# frozen_string_literal: true

module Mutations
  module CookieAuth
    extend ActiveSupport::Concern

    ACCESS_TOKEN_COOKIE = :access_token
    REFRESH_TOKEN_COOKIE = :refresh_token
    ACCESS_TOKEN_EXPIRY = 15.minutes
    REFRESH_TOKEN_EXPIRY = 7.days

    private

    def set_auth_cookies(user, response)
      access_token = user.generate_jwt
      _refresh_record, refresh_token = RefreshToken.generate_for(user)

      set_cookie(response, ACCESS_TOKEN_COOKIE, access_token, ACCESS_TOKEN_EXPIRY)
      set_cookie(response, REFRESH_TOKEN_COOKIE, refresh_token, REFRESH_TOKEN_EXPIRY)
    end

    def clear_auth_cookies(response)
      clear_cookie(response, ACCESS_TOKEN_COOKIE)
      clear_cookie(response, REFRESH_TOKEN_COOKIE)
    end

    def set_cookie(response, name, value, expiry)
      response.set_cookie(name, {
        value: value,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        expires: expiry.from_now,
        path: "/",
      })
    end

    def clear_cookie(response, name)
      response.delete_cookie(name, {
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
