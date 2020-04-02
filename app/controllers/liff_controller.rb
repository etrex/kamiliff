
class LiffController < ApplicationController
  layout false, only: :route


  def entry
    query = Rack::Utils.parse_nested_query(request.query_string)

    # fix liff 2.0 path issue
    if query["liff.state"].present?
      query = Rack::Utils.parse_nested_query(query["liff.state"][1..-1])
    end

    @path = query["path"]
  end

  def route
    path = params["path"]
    @body = reserve_route(path, request_params: source_info, format: :liff)
  end

  private

  def reserve_route(path, http_method: "GET", request_params: nil, format: nil)
    request.request_method = http_method
    request.path_info = path
    request.format = format if format.present?
    request.request_parameters = request_params if request_params.present?

    # req = Rack::Request.new
    # env = {Rack::RACK_INPUT => StringIO.new}

    res = Rails.application.routes.router.serve(request)
    res[2].body
  rescue
    res[2].to_s
  end

  def source_info
    context = params["context"]
    return nil if context.nil?

    source_type = context["type"].gsub("utou", "user")
    source_group_id = context["roomId"] || context["groupId"] || context["userId"]
    source_user_id = context["userId"]

    {
      platform_type: 'line',
      source_type: source_type,
      source_group_id: source_group_id,
      source_user_id: source_user_id,
    }
  end
end
