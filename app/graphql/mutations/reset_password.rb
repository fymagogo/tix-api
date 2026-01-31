# frozen_string_literal: true

module Mutations
  class ResetPassword < BaseMutation
    requires_auth false

    description "Reset password using token"

    argument :password, String, required: true
    argument :password_confirmation, String, required: true
    argument :token, String, required: true
    argument :user_type, String, required: false, default_value: "customer"

    field :success, Boolean, null: false

    def execute(token:, password:, password_confirmation:, user_type:)
      klass = user_type == "agent" ? Agent : Customer
      user = klass.reset_password_by_token(
        reset_password_token: token,
        password: password,
        password_confirmation: password_confirmation,
      )

      if user.errors.empty?
        { success: true }
      else
        user.errors.each do |err|
          error(err.full_message, field: err.attribute.to_s, code: "VALIDATION_ERROR")
        end
        { success: false }
      end
    end
  end
end
