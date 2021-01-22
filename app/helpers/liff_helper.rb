module LiffHelper
  def old_liff_path(params)
    liff = LiffService.new(params)
    if ENV["LIFF_MODE"]&.downcase == "replace"
      return "#{liff.url}/liff_entry?#{params.to_query}"
    end
    # liff mode is Concatenate
    "#{liff.url}?#{params.to_query}"
  end

  def liff_path(params)
    liff = LiffBase64Service.new(params)
    liff.full_url
  end
end