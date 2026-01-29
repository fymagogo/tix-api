# frozen_string_literal: true

module Mutations
  class ResetPassword < BaseMutation
    description "Reset password using token"

    argument :token, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true
    argument :user_type, String, required: false, default_value: "customer"

    field :success, Boolean, null: false
    field :errors, [Types::ErrorType], null: false

    def resolve(token:, password:, password_confirmation:, user_type:)
      klass = user_type == "agent" ? Agent : Customer
      user = klass.reset_password_by_token(
        reset_password_token: token,
        password: password,
        password_confirmation: password_confirmation
      )

      if user.errors.empty?
        { success: true, errors: [] }
      else
        { success: false, errors: format_errors(user) }
      end
    end

    private

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.message, code: "VALIDATION_ERROR" }
      end
    end
  end
end
