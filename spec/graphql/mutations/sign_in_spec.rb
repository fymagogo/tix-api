# frozen_string_literal: true

RSpec.describe Mutations::SignIn, type: :graphql do
  let(:query) do
    <<~GQL
      mutation SignIn($email: String!, $password: String!, $userType: String) {
        signIn(email: $email, password: $password, userType: $userType) {
          user {
            ... on Customer { id email name }
            ... on Agent { id email name }
          }
          errors { field message code }
        }
      }
    GQL
  end

  describe "customer sign in" do
    let!(:customer) { create(:customer, email: "test@example.com", password: "password123") }

    context "with valid credentials" do
      let(:variables) { { email: "test@example.com", password: "password123", userType: "customer" } }

      it "returns user and sets auth cookies" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["signIn"]
        expect(data["user"]["email"]).to eq("test@example.com")
        expect(data["errors"]).to be_empty

        # Verify cookies are set
        expect(response_cookies["access_token"]).to be_present
        expect(response_cookies["access_token"][:httponly]).to be true
        expect(response_cookies["refresh_token"]).to be_present
        expect(response_cookies["refresh_token"][:httponly]).to be true
      end
    end

    context "with invalid password" do
      let(:variables) { { email: "test@example.com", password: "wrong", userType: "customer" } }

      it "returns error and does not set cookies" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["signIn"]
        expect(data["user"]).to be_nil
        expect(data["errors"].first["code"]).to eq("INVALID_CREDENTIALS")
        expect(response_cookies["access_token"]).to be_nil
      end
    end

    context "with non-existent email" do
      let(:variables) { { email: "nonexistent@example.com", password: "password123", userType: "customer" } }

      it "returns error" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["signIn"]
        expect(data["user"]).to be_nil
        expect(data["errors"].first["code"]).to eq("INVALID_CREDENTIALS")
      end
    end
  end

  describe "agent sign in" do
    let!(:agent) { create(:agent, email: "agent@tix.test", password: "password123") }

    context "with valid credentials" do
      let(:variables) { { email: "agent@tix.test", password: "password123", userType: "agent" } }

      it "returns user and sets auth cookies" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["signIn"]
        expect(data["user"]["email"]).to eq("agent@tix.test")
        expect(data["errors"]).to be_empty

        # Verify cookies are set
        expect(response_cookies["access_token"]).to be_present
        expect(response_cookies["refresh_token"]).to be_present
      end
    end

    context "with wrong password" do
      let(:variables) { { email: "agent@tix.test", password: "wrong", userType: "agent" } }

      it "returns error" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["signIn"]
        expect(data["user"]).to be_nil
        expect(data["errors"].first["code"]).to eq("INVALID_CREDENTIALS")
      end
    end
  end

  describe "case-insensitive email" do
    let!(:customer) { create(:customer, email: "test@example.com", password: "password123") }
    let(:variables) { { email: "TEST@EXAMPLE.COM", password: "password123", userType: "customer" } }

    it "finds user regardless of email case" do
      result = execute_graphql(query: query, variables: variables)

      data = result["data"]["signIn"]
      expect(data["user"]["email"]).to eq("test@example.com")
    end
  end
end
