module LiffHelper
  def liff_path(params)
    liff = LiffService.new(params)
    "#{liff.url}/liff_entry?#{params.to_query}"
  end
end