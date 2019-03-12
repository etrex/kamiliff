module LiffHelper
  def liff_path(params)
    liff_size = params[:liff_size] || "COMPACT"
    raise "liff_size should be COMPACT, TALL or FULL." unless liff_size.in? %w[COMPACT TALL FULL]
    liff_url = ENV["LIFF_#{liff_size}"]
    "#{liff_url}?#{params.to_query}"
  end
end