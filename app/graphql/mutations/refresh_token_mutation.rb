# frozen_string_literal: true

module Mutations
  class RefreshTokenMutation < BaseMutation
    include CookieAuth

    requires_auth false

    description "Refresh access token using refresh token cookie"

    field :success, Boolean, null: true
    field :user, Types::CommentAuthorUnion, null: true

    def execute
      raw_token = refresh_token_from_cookies

      if raw_token.blank?
        clear_auth_cookies(context[:response])
        error("No refresh token", field: "base", code: "NO_REFRESH_TOKEN")
        return { success: false, user: nil }
      end

      refresh_token = RefreshToken.find_by_token(raw_token)

      if refresh_token.nil? || !refresh_token.valid_token?
        clear_auth_cookies(context[:response])
        error("Invalid or expired refresh token", field: "base", code: "INVALID_REFRESH_TOKEN")
        return { success: false, user: nil }
      end

      user = refresh_token.user

      # Rotate refresh token for security (prevents token reuse)
      refresh_token.revoke!
      set_auth_cookies(user, context[:response])

      { success: true, user: user }
    end
  end
end
