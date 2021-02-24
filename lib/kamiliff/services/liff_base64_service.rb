require "base64"

class LiffBase64Service

  # rails routes path
  attr_accessor :path

  # size
  # COMPACT TALL FULL
  attr_accessor :size

  # liff app url
  # https://liff.line.me/app/#{liff_id}
  attr_accessor :url

  # liff id
  attr_accessor :id

  def self.from_base64(base64_string)
    base64_string = base64_string.tr('-','+').tr('_','/')
    json = Base64.decode64(base64_string)
    options = JSON.parse(json)
    LiffBase64Service.new(options)
  end

  def to_base64
    json = {
      path: path,
      size: size
    }.to_json
    base64_string = Base64.encode64(json)
    base64_string.tr('+','-').tr('/','_').tr("\n", '').tr('=', '')
  end

  def initialize(options)
    options = options.with_indifferent_access
    self.path = options[:path] || "/"
    self.size = options[:size] || :compact
    self.size = size.to_s.upcase
    raise "liff_size should be compact, tall or full." unless size.in? %w[COMPACT TALL FULL]
    self.url = ENV["LIFF_#{size}"]
    raise "LIFF_#{size} should be in the env variables" if url.blank?
    self.id = url[(url.rindex('/')+1)..-1]
  end

  def full_url
    if ENV["LIFF_MODE"]&.downcase == "replace"
    end
    # liff mode is Concatenate
    "#{url}/#{to_base64}"
  end
end