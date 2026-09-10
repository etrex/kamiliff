# frozen_string_literal: true
class LiffController < ActionController::Base
  protect_from_forgery with: :exception

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
