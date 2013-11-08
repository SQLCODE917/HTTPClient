module EndpointArgumentValidation
# Looks like a beginning of a validation module

  # @param [Date, DateTime, String] date alleged date
  # @return [Date, DateTime] date verified date
  # @raise [ArgumentError] when argument is a String,
  #   but not like "YYYY-MM-DD"
  # @raise [ArgumentError] when argument is neither a Date,
  #   nor a parse-able String
  def checkDate( date )
    if date.is_a? Date or date.is_a? DateTime 
      return date
    elsif date.is_a? String
      #DateTime RegExp: From the beginning of the string 'till the end of the string,
      #4 digits, dash, 2 digits, dash, 2 digits, "T", 2 digits, ":", 2 digits, ":", 2 digits
      matchData = date.match /\A(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})\z/
      if matchData
        return DateTime.parse matchData[0]
      end
      #Date RegExp: From the beginning of the string 'till the end of the string,
      #4 digits, dash, 2 digits, dash, 2 digits
      matchData = date.match /\A\d{4}-\d{2}-\d{2}\z/
      if matchData
        return Date.parse matchData[0]
      else
        raise ArgumentError, "Date String needs to be like YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS"
      end
    else
      raise ArgumentError, "Date parameter is not a Date and could not be parsed as one"
    end
  end

  # @param [Date, String] startDate the range's alleged start
  # @param [Date, String] endDate the range's alleged end
  # @return [Date] start and end dates of a valid range
  # @raise [ArgumentError] when either of the arguments aren't dates
  # @raise [ArgumentError] when the end date precedes the start date 
  def checkDateRange( start_date, end_date )
    startDate = checkDate start_date
    endDate = checkDate end_date
    
    unless startDate <= endDate
      raise ArgumentError, "Start Date must precede End Date"
    end
    
    return startDate, endDate
  end

  # @param [Array] params arbitrary amount of parameters
  # @raise [ArgumentError] when any parameters are nils
  def checkForNils( *params )
    nilCount = params.length - params.compact.length 

    if nilCount > 0
      raise ArgumentError, "#{nilCount} nil(s) found in parameters ( #{params.join ", "} )"
    end
  end
end
