module LiffHelper
  def liff_path(entry:, liff_size: :compact)
    LiffService.new(entry: entry, liff_size: liff_size).full_url
  end
end
