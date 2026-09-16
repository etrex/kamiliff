# frozen_string_literal: true
require 'digest'
class LiffController < ActionController::Base
  protect_from_forgery with: :exception
  # Public static SDK contains no session-specific data; normal script tags
  # are intentionally supported without an XHR header.
  skip_after_action :verify_same_origin_request, only: :sdk

  def sdk
    source = Kamiliff::Engine.root.join('app/assets/javascripts/kamiliff.js')
    response.headers['X-Content-Type-Options'] = 'nosniff'
    expires_in 5.minutes, public: true
    return unless stale?(etag: Digest::SHA256.file(source).hexdigest, public: true)
    send_data File.binread(source), type: 'text/javascript; charset=utf-8', disposition: 'inline'
  end

  def entry
    handler = Kamiliff.entries[params[:entry].to_s]
    return head :not_found unless handler
    handler.call(self)
  end

  # Removed in 1.0: no user-supplied route/method dispatch or browser identity.
  def route
    head :gone
  end
end
