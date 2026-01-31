# frozen_string_literal: true

RSpec.describe Mutations::SignOut, type: :graphql do
  let(:query) do
    <<~GQL
      mutation SignOut {
        signOut {
          success
          errors { field message code }
        }
      }
    GQL
  end

  describe "sign out" do
    let!(:customer) { create(:customer) }
    let!(:refresh_token_record) { RefreshToken.generate_for(customer) }
    let(:raw_token) { refresh_token_record.last }

    it "clears auth cookies and revokes refresh token" do
      result = execute_graphql(
        query: query,
        cookies: { refresh_token: raw_token },
      )

      data = result["data"]["signOut"]
      expect(data["success"]).to be true
      expect(data["errors"]).to be_empty

      # Verify refresh token is revoked
      refresh_token_record.first.reload
      expect(refresh_token_record.first.revoked?).to be true
    end

    it "succeeds even without existing refresh token" do
      result = execute_graphql(query: query)

      data = result["data"]["signOut"]
      expect(data["success"]).to be true
    end
  end
end
