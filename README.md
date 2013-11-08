HTTPClient
==========

I couldn't introduce new gems into a legacy codebase, so I rolled my own RESTful-ish HTTP client

Can do the minimum I needed: GET, PUT and POST

Use like this:

require 'HTTPRequest'
require 'net/https'
require 'uri'

def update message
  #do something with the status messages
end
 
HTTPRequest.add_observer(self)

uri = URI::HTTPS.build( {
  :host => 'my.host.com',
  :port => '12345',
  :path => '/path/to/endpoint'
})

requestParameters = {
  'key' => value 
}

# true to toggle SSL
responseBody = HTTPRequest.getResponseBody( uri, requestParameters, true )
