class LiffService

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

  def initialize(options)
    self.path = options[:path] || options['path'] || "/"
    self.size = options[:liff_size] || options['liff_size'] || :compact
    self.size = size.to_s.upcase
    raise "liff_size should be compact, tall or full." unless size.in? %w[COMPACT TALL FULL]
    self.url = ENV["LIFF_#{size}"]
    raise "LIFF_#{size} should be in the env variables" if url.empty?
    self.id = url[(url.rindex('/')+1)..-1]
  end
end