# frozen_string_literal: true

RSpec.describe Mutations::RefreshTokenMutation, type: :graphql do
  let(:query) do
    <<~GQL
      mutation RefreshToken {
        refreshToken {
          success
          user {
            ... on Customer { id email name }
            ... on Agent { id email name }
          }
          errors { field message code }
        }
      }
    GQL
  end

  describe "with valid refresh token" do
    let!(:customer) { create(:customer, email: "test@example.com") }
    let!(:token_pair) { RefreshToken.generate_for(customer) }
    let(:raw_token) { token_pair.last }

    it "issues new access token and rotates refresh token" do
      result = execute_graphql(
        query: query,
        cookies: { refresh_token: raw_token },
      )

      data = result["data"]["refreshToken"]
      expect(data["success"]).to be true
      expect(data["user"]["email"]).to eq("test@example.com")
      expect(data["errors"]).to be_empty

      # Verify new cookies are set
      expect(response_cookies["access_token"]).to be_present
      expect(response_cookies["refresh_token"]).to be_present

      # Verify old token is revoked
      token_pair.first.reload
      expect(token_pair.first.revoked?).to be true
    end
  end

  describe "with expired refresh token" do
    let!(:customer) { create(:customer) }
    let!(:expired_token) do
      token = RefreshToken.generate_for(customer)
      token.first.update!(expires_at: 1.day.ago)
      token
    end

    it "returns error and clears cookies" do
      result = execute_graphql(
        query: query,
        cookies: { refresh_token: expired_token.last },
      )

      data = result["data"]["refreshToken"]
      expect(data["success"]).to be false
      expect(data["user"]).to be_nil
      expect(data["errors"].first["code"]).to eq("INVALID_REFRESH_TOKEN")
    end
  end

  describe "with revoked refresh token" do
    let!(:customer) { create(:customer) }
    let!(:revoked_token) do
      token = RefreshToken.generate_for(customer)
      token.first.revoke!
      token
    end

    it "returns error" do
      result = execute_graphql(
        query: query,
        cookies: { refresh_token: revoked_token.last },
      )

      data = result["data"]["refreshToken"]
      expect(data["success"]).to be false
      expect(data["errors"].first["code"]).to eq("INVALID_REFRESH_TOKEN")
    end
  end

  describe "without refresh token" do
    it "returns error" do
      result = execute_graphql(query: query)

      data = result["data"]["refreshToken"]
      expect(data["success"]).to be false
      expect(data["errors"].first["code"]).to eq("NO_REFRESH_TOKEN")
    end
  end

  describe "with agent user" do
    let!(:agent) { create(:agent, email: "agent@tix.test") }
    let!(:token_pair) { RefreshToken.generate_for(agent) }

    it "returns agent user" do
      result = execute_graphql(
        query: query,
        cookies: { refresh_token: token_pair.last },
      )

      data = result["data"]["refreshToken"]
      expect(data["success"]).to be true
      expect(data["user"]["email"]).to eq("agent@tix.test")
    end
  end
end
