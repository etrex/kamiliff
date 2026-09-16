module LiffHelper
  def kamiliff_url(application, **parameters)
    Kamiliff.application(application).url(**parameters)
  end

  def liff_path(entry:, liff_size: :compact)
    LiffService.new(entry: entry, liff_size: liff_size).full_url
  end
end
