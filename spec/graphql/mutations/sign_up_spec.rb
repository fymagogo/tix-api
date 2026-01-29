# frozen_string_literal: true

RSpec.describe Mutations::SignUp, type: :graphql do
  let(:query) do
    <<~GQL
      mutation SignUp($email: String!, $name: String!, $password: String!, $passwordConfirmation: String!) {
        signUp(email: $email, name: $name, password: $password, passwordConfirmation: $passwordConfirmation) {
          customer { id email name }
          token
          errors { field message code }
        }
      }
    GQL
  end

  describe "successful signup" do
    it "creates customer and returns token" do
      result = execute_graphql(
        query: query,
        variables: {
          email: "new@test.com",
          name: "New Customer",
          password: "password123",
          passwordConfirmation: "password123",
        },
      )

      data = result["data"]["signUp"]
      expect(data["customer"]["email"]).to eq("new@test.com")
      expect(data["customer"]["name"]).to eq("New Customer")
      expect(data["token"]).to be_present
      expect(data["errors"]).to be_empty
    end
  end

  describe "validation errors" do
    it "returns errors for password mismatch" do
      result = execute_graphql(
        query: query,
        variables: {
          email: "new@test.com",
          name: "New Customer",
          password: "password123",
          passwordConfirmation: "different",
        },
      )

      data = result["data"]["signUp"]
      expect(data["customer"]).to be_nil
      expect(data["token"]).to be_nil
      expect(data["errors"]).not_to be_empty
      expect(data["errors"].first["field"]).to eq("password_confirmation")
    end

    it "returns errors for duplicate email" do
      create(:customer, email: "existing@test.com")

      result = execute_graphql(
        query: query,
        variables: {
          email: "existing@test.com",
          name: "New Customer",
          password: "password123",
          passwordConfirmation: "password123",
        },
      )

      data = result["data"]["signUp"]
      expect(data["customer"]).to be_nil
      expect(data["errors"]).not_to be_empty
      expect(data["errors"].first["field"]).to eq("email")
    end

    it "returns errors for short password" do
      result = execute_graphql(
        query: query,
        variables: {
          email: "new@test.com",
          name: "New Customer",
          password: "short",
          passwordConfirmation: "short",
        },
      )

      data = result["data"]["signUp"]
      expect(data["customer"]).to be_nil
      expect(data["errors"]).not_to be_empty
    end
  end
end
