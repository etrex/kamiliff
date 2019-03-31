
class LiffController < ApplicationController
  # layout :liff
  layout false, only: :route


  def entry
    query = Rack::Utils.parse_nested_query(request.query_string)
    @path = query["path"]
  end

  def route
    path = params["path"]
    @body = reserve_route(path, format: :liff)
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
end
