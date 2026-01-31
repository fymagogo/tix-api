# frozen_string_literal: true

module Mutations
  class SignOut < BaseMutation
    include CookieAuth

    requires_auth false

    description "Sign out and clear authentication cookies"

    field :success, Boolean, null: false

    def execute
      # Revoke the refresh token if it exists
      raw_token = refresh_token_from_cookies
      if raw_token.present?
        refresh_token = RefreshToken.find_by_token(raw_token)
        refresh_token&.revoke!
      end

      # Clear auth cookies
      clear_auth_cookies(context[:response])

      { success: true }
    end
  end
end
