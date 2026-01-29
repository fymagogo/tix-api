# frozen_string_literal: true

RSpec.describe Mutations::ResetPassword, type: :graphql do
  let(:query) do
    <<~GQL
      mutation ResetPassword($token: String!, $password: String!, $passwordConfirmation: String!, $userType: String) {
        resetPassword(token: $token, password: $password, passwordConfirmation: $passwordConfirmation, userType: $userType) {
          success
          errors { field message code }
        }
      }
    GQL
  end

  describe "customer password reset" do
    let!(:customer) { create(:customer, email: "customer@example.com") }
    let(:reset_token) { customer.send_reset_password_instructions }

    context "with valid token and matching passwords" do
      let(:variables) do
        {
          token: reset_token,
          password: "newpassword123",
          passwordConfirmation: "newpassword123",
          userType: "customer"
        }
      end

      it "resets password successfully" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["resetPassword"]
        expect(data["success"]).to be true
        expect(data["errors"]).to be_empty
      end

      it "allows login with new password" do
        execute_graphql(query: query, variables: variables)
        expect(customer.reload.valid_password?("newpassword123")).to be true
      end
    end

    context "with password mismatch" do
      let(:variables) do
        {
          token: reset_token,
          password: "newpassword123",
          passwordConfirmation: "different",
          userType: "customer"
        }
      end

      it "returns validation error" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["resetPassword"]
        expect(data["success"]).to be false
        expect(data["errors"]).not_to be_empty
      end
    end

    context "with invalid token" do
      let(:variables) do
        {
          token: "invalid-token",
          password: "newpassword123",
          passwordConfirmation: "newpassword123",
          userType: "customer"
        }
      end

      it "returns validation error" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["resetPassword"]
        expect(data["success"]).to be false
        expect(data["errors"]).not_to be_empty
      end
    end
  end

  describe "agent password reset" do
    let!(:agent) { create(:agent, email: "agent@tix.test") }
    let(:reset_token) { agent.send_reset_password_instructions }
    let(:variables) do
      {
        token: reset_token,
        password: "newpassword123",
        passwordConfirmation: "newpassword123",
        userType: "agent"
      }
    end

    it "resets password successfully" do
      result = execute_graphql(query: query, variables: variables)

      data = result["data"]["resetPassword"]
      expect(data["success"]).to be true
    end
  end
end
