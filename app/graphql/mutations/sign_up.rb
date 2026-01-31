# frozen_string_literal: true

module Mutations
  class SignUp < BaseMutation
    include CookieAuth

    requires_auth false

    description "Register a new customer account"

    argument :email, String, required: true
    argument :name, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true

    field :customer, Types::CustomerType, null: true

    def execute(email:, name:, password:, password_confirmation:)
      customer = Customer.new(
        email: email,
        name: name,
        password: password,
        password_confirmation: password_confirmation,
      )

      customer.save!
      set_auth_cookies(customer, context[:response])
      { customer: customer }
    end
  end
end
