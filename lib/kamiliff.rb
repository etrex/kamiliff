require "kamiliff/engine"
require "kamiliff/services/base64_encode_service"
require "kamiliff/services/base64_decode_service"
require "kamiliff/services/liff_service"
require "line_login"

module Kamiliff
  # env
  mattr_writer :line_login_channel_id
  mattr_writer :line_login_channel_secret
  mattr_writer :line_login_redirect_uri

  mattr_writer :liff_url_compact
  mattr_writer :liff_url_tall
  mattr_writer :liff_url_full

  def self.line_login_channel_id
    @@line_login_channel_id || ENV["LINE_LOGIN_CHANNEL_ID"]
  end

  def self.line_login_channel_secret
    @@line_login_channel_secret || ENV["LINE_LOGIN_CHANNEL_SECRET"]
  end

  def self.line_login_redirect_uri
    @@line_login_redirect_uri || ENV["LINE_LOGIN_REDIRECT_URI"]
  end

  def self.liff_url_compact
    @@liff_url_compact || ENV["LIFF_COMPACT"]
  end

  def self.liff_url_tall
    @@liff_url_tall || ENV["LIFF_TALL"]
  end

  def self.liff_url_full
    @@liff_url_full || ENV["LIFF_FULL"]
  end

  def self.line_login_client
    @line_login_client ||= LineLogin::Client.new(
      client_id: Kamiliff.line_login_channel_id,
      client_secret: Kamiliff.line_login_channel_secret
    )
  end

  def self.setup
    yield self
  end
end
