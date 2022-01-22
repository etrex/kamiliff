
class LiffController < ActionController::Base
  layout false, only: :route
  before_action :set_liff_param, only: [:entry]

  def entry
    @liff = LiffService.new(@liff_param)
  end

  def route
    path, query = params["path"].split("?")
    query = Rack::Utils.parse_nested_query(query)
    http_method = query["_method"]&.upcase || "GET"
    @body = reserve_route(path, http_method: http_method, request_params: source_info.merge(query), format: :liff)
  end

  private

  # {"path"=>"/orders", "liff_size"=>"TALL"}
  def set_liff_param
    query = Rack::Utils.parse_nested_query(request.query_string)

    # fix liff 2.0 redirect issue
    @need_reload = query["liff.state"].present?

    # 需要從 session 讀取 @liff_param (使用電腦開啟 LIFF 頁面，第一次登入時的情況)
    if query["liffRedirectUri"].present?
      @liff_param = Base64DecodeService.new(session[:liff_param]).run
      session[:liff_param] = nil
      return
    end

    # 第一次 redirect
    if(@need_reload)
      # base64 的情況
      if(query["liff.state"][0] == '/')
        base64_string = query["liff.state"][1..-1]
        @liff_param = Base64DecodeService.new(base64_string).run
      # query 的情況
      else
        querystring = query["liff.state"][(query["liff.state"].index('?')+1)..-1]
        @liff_param = Rack::Utils.parse_nested_query(querystring)
      end
    # 第二次 redirect
    else
      # base64 的情況
      if params[:base64].present?
        base64_string = params[:base64]
        @liff_param = Base64DecodeService.new(base64_string).run
      # query 的情況
      else
        @liff_param = query
      end
    end

    # 保存最後一次 liff_param 到 session
    session[:liff_param] = Base64EncodeService.new(@liff_param).run
  end

  def reserve_route(path, http_method: "GET", request_params: nil, format: nil)
    request.request_method = http_method
    request.path_info = path
    request.format = format if format.present?
    request.request_parameters = request_params if request_params.present?

    # req = Rack::Request.new
    # env = {Rack::RACK_INPUT => StringIO.new}

    res = Rails.application.routes.router.serve(request)
    # res[0]: http state code
    # res[1]: headers
    # res[2]: response
    res[2].body
  rescue NoMethodError => e
    res&.to_s || e.full_message
  end


  # profile format
  # {
  #   "userId"=>"U1234567890abcdefghijklmnopqrstuv",
  #   "displayName"=>"user name",
  #   "statusMessage"=>"user status message",
  #   "pictureUrl"=>"https://this.is.an.image.url"
  # }
  def source_info
    context = params["context"]
    return {
      platform_type: 'line',
      liff_error: 'context not found',
    } if context.nil?

    profile = params["profile"]
    return {
      platform_type: 'line',
      liff_error: 'profile not found',
    } if profile.nil?

    # authorize the user id
    decoded_id_token = get_decoded_id_token
    return {
      platform_type: 'line',
      liff_error: 'user id does not match',
    } unless decoded_id_token["sub"] == context["userId"] && decoded_id_token["sub"] == profile["userId"]

    source_type = context["type"].gsub("utou", "user")
    source_group_id = context["roomId"] || context["groupId"] || decoded_id_token["sub"]
    source_user_id = decoded_id_token["sub"]

    {
      platform_type: 'line',
      source_type: source_type,
      source_group_id: source_group_id,
      source_user_id: source_user_id,
      context: context,
      profile: profile,
      decoded_id_token: decoded_id_token
    }
  end

  # decoded_id_token is JWT format
  # {
  #  "iss"=>"https://access.line.me",
  #  "sub"=>"U1234567890abcdefghijklmnopqrstuv",
  #  "aud"=>"1234567890",
  #  "exp"=>1641638901,
  #  "iat"=>1641635301,
  #  "name"=>"user name",
  #  "picture"=>"https://this.is.an.image.url"
  # }
  def get_decoded_id_token
    id_token = params["idToken"]
    Kamiliff.line_login_client.verify_id_token(id_token: id_token)
  end

end
