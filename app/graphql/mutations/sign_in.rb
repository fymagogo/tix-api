# frozen_string_literal: true

module Mutations
  class SignIn < BaseMutation
    description "Sign in as customer or agent"

    argument :email, String, required: true
    argument :password, String, required: true
    argument :user_type, String, required: false, default_value: "customer",
             description: "Type of user: 'customer' or 'agent'"

    field :user, Types::CommentAuthorUnion, null: true
    field :token, String, null: true
    field :errors, [Types::ErrorType], null: false

    def resolve(email:, password:, user_type:)
      klass = user_type == "agent" ? Agent : Customer
      user = klass.find_by(email: email.downcase)

      if user&.valid_password?(password)
        token = user.generate_jwt
        { user: user, token: token, errors: [] }
      else
        { user: nil, token: nil, errors: [{ field: "base", message: "Invalid email or password", code: "INVALID_CREDENTIALS" }] }
      end
    end
  end
end
