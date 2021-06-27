require "base64"

class Base64DecodeService

  def initialize(base64_string)
    @base64_string = base64_string
  end

  def run
    json = Base64.decode64(@base64_string)
    options = JSON.parse(json)
    options.with_indifferent_access
  end

end