# frozen_string_literal: true

module Mutations
  class RequestPasswordReset < BaseMutation
    requires_auth false

    description "Request a password reset email"

    argument :email, String, required: true
    argument :user_type, String, required: false, default_value: "customer"

    field :success, Boolean, null: false

    def execute(email:, user_type:)
      klass = user_type == "agent" ? Agent : Customer
      user = klass.find_by(email: email.downcase)

      # Always return success to prevent email enumeration
      user&.send_reset_password_instructions

      { success: true }
    end
  end
end
