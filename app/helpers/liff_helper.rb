module LiffHelper
  def liff_path(params)
    liff_size = params[:liff_size] || :compact
    liff_size = liff_size.to_s.upcase
    raise "liff_size should be compact, tall or full." unless liff_size.in? %w[COMPACT TALL FULL]
    liff_url = ENV["LIFF_#{liff_size}"]
    "#{liff_url}?#{params.to_query}"
  end
end