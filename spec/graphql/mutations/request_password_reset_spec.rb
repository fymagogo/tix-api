# frozen_string_literal: true

RSpec.describe Mutations::RequestPasswordReset, type: :graphql do
  let(:query) do
    <<~GQL
      mutation RequestPasswordReset($email: String!, $userType: String) {
        requestPasswordReset(email: $email, userType: $userType) {
          success
          errors { field message code }
        }
      }
    GQL
  end

  describe "customer password reset" do
    let!(:customer) { create(:customer, email: "customer@example.com") }

    context "with existing email" do
      let(:variables) { { email: "customer@example.com", userType: "customer" } }

      it "returns success" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["requestPasswordReset"]
        expect(data["success"]).to be true
        expect(data["errors"]).to be_empty
      end
    end

    context "with non-existent email" do
      let(:variables) { { email: "nonexistent@example.com", userType: "customer" } }

      it "still returns success to prevent enumeration" do
        result = execute_graphql(query: query, variables: variables)

        data = result["data"]["requestPasswordReset"]
        expect(data["success"]).to be true
        expect(data["errors"]).to be_empty
      end
    end
  end

  describe "agent password reset" do
    let!(:agent) { create(:agent, email: "agent@tix.test") }
    let(:variables) { { email: "agent@tix.test", userType: "agent" } }

    it "returns success" do
      result = execute_graphql(query: query, variables: variables)

      data = result["data"]["requestPasswordReset"]
      expect(data["success"]).to be true
    end
  end

  describe "case-insensitive email lookup" do
    let!(:customer) { create(:customer, email: "test@example.com") }
    let(:variables) { { email: "TEST@EXAMPLE.COM", userType: "customer" } }

    it "finds user regardless of case" do
      result = execute_graphql(query: query, variables: variables)
      expect(result["data"]["requestPasswordReset"]["success"]).to be true
    end
  end
end
