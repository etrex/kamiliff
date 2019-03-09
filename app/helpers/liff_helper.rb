module LiffHelper
  def liff_path(params)
    liff_url = ENV['LIFF_FORM']
    "#{liff_url}?#{params.to_query}"
  end
end