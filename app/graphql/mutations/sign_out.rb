# frozen_string_literal: true

module Mutations
  class SignOut < BaseMutation
    include CookieAuth

    requires_auth false

    description "Sign out and clear authentication cookies"

    argument :user_type, String, required: false, default_value: "customer",
                                 description: "Type of user: 'customer' or 'agent'"

    field :success, Boolean, null: false

    def execute(user_type:)
      cookie_name = user_type == "agent" ? "agent_refresh_token" : "customer_refresh_token"
      raw_token = context[:request]&.cookies&.fetch(cookie_name, nil)

      # Revoke the refresh token if it exists
      if raw_token.present?
        refresh_token = RefreshToken.find_by_token(raw_token)
        refresh_token&.revoke!
      end

      # Clear auth cookies for this user type only
      clear_auth_cookies(context[:response], user_type: user_type.to_sym)

      { success: true }
    end
  end
end
