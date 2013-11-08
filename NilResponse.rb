# @note one does not suffer a nil to live!
#   instead of passing in nils or false or other bad value flags,
#   pass in an object that acts like a response, but carries no meaning
class NilResponse

  # @note this is the only method that is used by endpoint access libraries
  # @return [String] JSON String for {}
  def body
    "{}"
  end
end
