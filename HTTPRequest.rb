require 'observer'
require 'rubygems'
require 'activesupport'
require File.dirname(__FILE__) + "/NilResponse"
# Warning - net::http does not verify SSL certificates by default

module HTTPRequest
  extend Observable
  @@RETRY_LIMIT = 4 # number of times to retry a connection that is timing out
  # Default timeout is 15 seconds
  @@SECONDS_UNTIL_TIMEOUT = 30

  # Convenience functions

  # @param [String] uri endpoint URI
  # @param [Hash] data GET data
  # @param [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS
  def self.getRequestBody( uri, data = {}, ssl = false )
    getRequest( uri, data, ssl ).body
  end

  # @param [String] uri endpoint URI
  # @param [Hash] data POST data
  # @param [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS
  def self.postRequestBody( uri, data = {}, ssl = false )
    postRequest( uri, data, ssl ).body
  end

  # @param [String] uri endpoint URI
  # @param [Hash] data PUT data
  # @param [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS
  def self.putRequestBody( uri, data = {}, ssl = false )
    putRequest( uri, data, ssl ).body
  end

  # HTTP Verbs

  # @note HTTP(S) GET request
  # @param [String] uri endpoint URI
  # @param [Hash] data GET parameters
  # @param [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS
  def self.getRequest( uri, data = {}, ssl = false )
    uri.query = data.collect{ |a,b| a.to_s + '=' + b.to_s}.join('&')

    getRequest = Proc.new do |uri| Net::HTTP::Get.new uri.request_uri end

    httpRequest( uri,
        {:ssl => ssl },
        getRequest )
  end

  # @note HTTP(S) POST request
  # @param [String] uri endpointURI
  # @param [Hash] data POST data 
  # @param [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS 
  def self.postRequest( uri, data = {}, ssl = false )
    
    postRequest = Proc.new do |uri|
      request = Net::HTTP::Post.new uri.request_uri
      request.set_form_data data
      request
    end

    httpRequest( uri,
        {:ssl => ssl },
        postRequest )
  end

  # @note HTTP(S) PUT request
  # @param [String] uri endpoint URI
  # @param [Hash] data PUT data
  # @ssl [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS
  def self.putRequest( uri, data ={}, ssl = false )
    jsonData = ActiveSupport::JSON.encode data
   
    putRequest = Proc.new do |uri|
      request = Net::HTTP::Put.new uri.request_uri
      request["content-type"] = "application/json"
      request.body = jsonData
      request
    end

    httpRequest( uri,
      {:ssl => ssl },
      putRequest )
  end

private

  # @note generic HTTP(S) request
  # @param [String] uri endpoint URI
  # @param [Hash] options request options
  # @param [TrueClass, FalseClass] ssl flag that toggles between HTTP and HTTPS
  # @param [Proc] block code that defines a specific HTTP request
  # @return [Net::HTTPResponse] response
  # @raise [Timeout::Error] for timeouts that go above and beyond the call
  # @raise [RuntimeError] for excessive redirects
  def self.httpRequest( uri, options, block )
    uri = URI.parse( uri ) if uri.is_a? String

    changed
    notify_observers "Requesting from host [#{uri.host}]  #{uri.request_uri}"

    http = Net::HTTP.new( uri.host, uri.port )
    # Defauly timeout is 15 seconds.
    # For 5-minute raw usage endpoint, that is not enough
    http.read_timeout = @@SECONDS_UNTIL_TIMEOUT
    http.open_timeout = @@SECONDS_UNTIL_TIMEOUT
    http.use_ssl = options[:ssl] ||= false
    
    #create a request as directed by more specific functions
    request = block.call(uri)

    retries = 0
    response = nil

    begin
      response = http.request( request )
    rescue Timeout::Error => e
      requestProtocol = http.use_ssl? ? 'HTTPS' : 'HTTP'
      if retries >= @@RETRY_LIMIT
        changed
        notify_observers "Request for #{uri} (#{requestProtocol}) had timed out #{retries} time(s) - returning an empty set"
        return NilResponse.new
      end 
      retries += 1
      changed
      notify_observers "Request for #{uri} (#{requestProtocol}) had timed out #{retries} time(s) - retrying..."
      retry
    rescue EOFError => e
      changed
      # I have encountered these errors when trying to send HTTP requests instead of HTTPS
      requestProtocol = http.use_ssl? ? 'HTTPS' : 'HTTP'
      notify_observers "Error while processing an #{requestProtocol} request for #{uri} - Endpoint might require SSL - returning an empty set"
      return NilResponse.new
    rescue OpenSSL::SSL::SSLError => e
      changed
      # I have encountered these errors when sending HTTPS requests instead of HTTP
      requestProtocol = http.use_ssl? ? 'HTTPS' : 'HTTP'
      notify_observers "Error while processing an #{requestProtocol} request for #{uri} - Check your SSL privilege - returning an empty set"
      return NilResponse.new
    rescue Errno::ECONNREFUSED => e
      changed
      notify_observers "Connection refused for #{request.inspect} - returning an empty set"
      return NilResponse.new
    rescue Exception => e
      requestProtocol = http.use_ssl? ? 'HTTPS' : 'HTTP'
      changed
      notify_observers "Error while processing an #{requestProtocol} request for #{uri}: #{e.inspect} - returning an empty set"
      return NilResponse.new
    end
    
    case response
    when Net::HTTPSuccess then return response
    else
      changed
      notify_observers "An Unsuccessful #{requestProtocol} request for #{uri} was attempted. #{response.inspect}"
      NilResponse.new
    end
  end
end
