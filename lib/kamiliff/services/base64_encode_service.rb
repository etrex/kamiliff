require "base64"

class Base64EncodeService

  def initialize(options)
    @options = options
  end

  def run
    json = @options.to_json
    base64_string = Base64.encode64(json)
    base64_string.tr('+','-').tr('/','_').tr("\n", '').tr('=', '')
  end

end