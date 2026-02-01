# frozen_string_literal: true

RSpec.describe Mutations::SignOut, type: :graphql do
  let(:customer_query) do
    <<~GQL
      mutation SignOut {
        signOut(userType: "customer") {
          success
          errors { field message code }
        }
      }
    GQL
  end

  let(:agent_query) do
    <<~GQL
      mutation SignOut {
        signOut(userType: "agent") {
          success
          errors { field message code }
        }
      }
    GQL
  end

  describe "customer sign out" do
    let!(:customer) { create(:customer) }
    let!(:refresh_token_record) { RefreshToken.generate_for(customer) }
    let(:raw_token) { refresh_token_record.last }

    it "clears auth cookies and revokes refresh token" do
      result = execute_graphql(
        query: customer_query,
        cookies: { customer_refresh_token: raw_token },
      )

      data = result["data"]["signOut"]
      expect(data["success"]).to be true
      expect(data["errors"]).to be_empty

      # Verify refresh token is revoked
      refresh_token_record.first.reload
      expect(refresh_token_record.first.revoked?).to be true
    end

    it "succeeds even without existing refresh token" do
      result = execute_graphql(query: customer_query)

      data = result["data"]["signOut"]
      expect(data["success"]).to be true
    end
  end

  describe "agent sign out" do
    let!(:agent) { create(:agent) }
    let!(:refresh_token_record) { RefreshToken.generate_for(agent) }
    let(:raw_token) { refresh_token_record.last }

    it "clears agent auth cookies and revokes refresh token" do
      result = execute_graphql(
        query: agent_query,
        cookies: { agent_refresh_token: raw_token },
      )

      data = result["data"]["signOut"]
      expect(data["success"]).to be true

      # Verify refresh token is revoked
      refresh_token_record.first.reload
      expect(refresh_token_record.first.revoked?).to be true
    end
  end
end
