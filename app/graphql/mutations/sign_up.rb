# frozen_string_literal: true

module Mutations
  class SignUp < BaseMutation
    description "Register a new customer account"

    argument :email, String, required: true
    argument :name, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true

    field :customer, Types::CustomerType, null: true
    field :token, String, null: true
    field :errors, [Types::ErrorType], null: false

    def resolve(email:, name:, password:, password_confirmation:)
      customer = Customer.new(
        email: email,
        name: name,
        password: password,
        password_confirmation: password_confirmation
      )

      if customer.save
        token = customer.generate_jwt
        { customer: customer, token: token, errors: [] }
      else
        { customer: nil, token: nil, errors: format_errors(customer) }
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
