# frozen_string_literal: true

module Mutations
  class RefreshTokenMutation < BaseMutation
    include CookieAuth

    requires_auth false

    description "Refresh access token using refresh token cookie"

    argument :user_type, String, required: false, default_value: "customer",
                                 description: "Type of user: 'customer' or 'agent'"

    field :success, Boolean, null: true
    field :user, Types::CommentAuthorUnion, null: true

    def execute(user_type:)
      cookie_name = user_type == "agent" ? "agent_refresh_token" : "customer_refresh_token"
      raw_token = context[:request]&.cookies&.fetch(cookie_name, nil)

      if raw_token.blank?
        clear_auth_cookies(context[:response], user_type: user_type.to_sym)
        error("No refresh token", field: "base", code: "NO_REFRESH_TOKEN")
        return { success: false, user: nil }
      end

      refresh_token = RefreshToken.find_by_token(raw_token)

      if refresh_token.nil? || !refresh_token.valid_token?
        clear_auth_cookies(context[:response], user_type: user_type.to_sym)
        error("Invalid or expired refresh token", field: "base", code: "INVALID_REFRESH_TOKEN")
        return { success: false, user: nil }
      end

      user = refresh_token.user

      # Verify user type matches
      expected_class = user_type == "agent" ? Agent : Customer
      unless user.is_a?(expected_class)
        clear_auth_cookies(context[:response], user_type: user_type.to_sym)
        error("Token does not match user type", field: "base", code: "USER_TYPE_MISMATCH")
        return { success: false, user: nil }
      end

      # Rotate refresh token for security (prevents token reuse)
      refresh_token.revoke!
      set_auth_cookies(user, context[:response])

      { success: true, user: user }
    end
  end
end
