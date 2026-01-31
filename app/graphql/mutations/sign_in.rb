# frozen_string_literal: true

module Mutations
  class SignIn < BaseMutation
    include CookieAuth

    requires_auth false

    description "Sign in as customer or agent"

    argument :email, String, required: true
    argument :password, String, required: true
    argument :user_type, String, required: false, default_value: "customer",
                                 description: "Type of user: 'customer' or 'agent'"

    field :user, Types::CommentAuthorUnion, null: true

    def execute(email:, password:, user_type:)
      klass = user_type == "agent" ? Agent : Customer
      user = klass.find_by(email: email.downcase)

      unless user&.valid_password?(password)
        error!("Invalid email or password", field: "base", code: "INVALID_CREDENTIALS")
      end

      set_auth_cookies(user, context[:response])
      { user: user }
    end
  end
end
