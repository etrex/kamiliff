
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

    # 需要從 session 讀取 @liff_param
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

  def source_info
    context = params["context"]
    return nil if context.nil?

    source_type = context["type"].gsub("utou", "user")
    source_group_id = context["roomId"] || context["groupId"] || context["userId"]
    source_user_id = context["userId"]

    profile = params["profile"]

    {
      platform_type: 'line',
      source_type: source_type,
      source_group_id: source_group_id,
      source_user_id: source_user_id,
      profile: profile
    }
  end
end
