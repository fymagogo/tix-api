# frozen_string_literal: true

module Mutations
  module CookieAuth
    extend ActiveSupport::Concern

    ACCESS_TOKEN_EXPIRY = 15.minutes
    REFRESH_TOKEN_EXPIRY = 7.days

    private

    # Cookie names are scoped by user type to allow simultaneous sessions
    def access_token_cookie_name(user)
      user.is_a?(Agent) ? "agent_access_token" : "customer_access_token"
    end

    def refresh_token_cookie_name(user)
      user.is_a?(Agent) ? "agent_refresh_token" : "customer_refresh_token"
    end

    def set_auth_cookies(user, response)
      access_token = user.generate_jwt
      _refresh_record, refresh_token = RefreshToken.generate_for(user)

      set_cookie(response, access_token_cookie_name(user), access_token, ACCESS_TOKEN_EXPIRY)
      set_cookie(response, refresh_token_cookie_name(user), refresh_token, REFRESH_TOKEN_EXPIRY)
    end

    def clear_auth_cookies(response, user_type: nil)
      if user_type == :agent || user_type.nil?
        clear_cookie(response, "agent_access_token")
        clear_cookie(response, "agent_refresh_token")
      end

      return unless user_type == :customer || user_type.nil?

      clear_cookie(response, "customer_access_token")
      clear_cookie(response, "customer_refresh_token")
    end

    def set_cookie(response, name, value, expiry)
      response.set_cookie(name.to_s, {
        value: value,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: expiry.from_now,
        path: "/",
      })
    end

    def clear_cookie(response, name)
      response.delete_cookie(name.to_s, {
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        path: "/",
      })
    end

    def refresh_token_from_cookies
      context[:request]&.cookies&.fetch(REFRESH_TOKEN_COOKIE.to_s, nil)
    end
  end
end
