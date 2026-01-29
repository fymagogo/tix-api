# frozen_string_literal: true

RSpec.describe Mutations::AcceptInvite, type: :graphql do
  let(:query) do
    <<~GQL
      mutation AcceptInvite($invitationToken: String!, $password: String!, $passwordConfirmation: String!) {
        acceptInvite(invitationToken: $invitationToken, password: $password, passwordConfirmation: $passwordConfirmation) {
          agent {
            id
            email
            name
          }
          token
          errors { field message code }
        }
      }
    GQL
  end

  let(:admin) { create(:agent, :admin) }
  let!(:invited_agent) do
    Agent.invite!({ email: "invited@tix.test", name: "Invited Agent" }, admin)
  end

  describe "with valid token and matching passwords" do
    let(:variables) do
      {
        invitationToken: invited_agent.raw_invitation_token,
        password: "newpassword123",
        passwordConfirmation: "newpassword123"
      }
    end

    it "accepts invitation and returns token" do
      result = execute_graphql(query: query, variables: variables)

      data = result["data"]["acceptInvite"]
      expect(data["agent"]["email"]).to eq("invited@tix.test")
      expect(data["token"]).to be_present
      expect(data["errors"]).to be_empty
    end

    it "marks invitation as accepted" do
      execute_graphql(query: query, variables: variables)
      expect(invited_agent.reload.invitation_accepted_at).to be_present
    end
  end

  describe "with password mismatch" do
    let(:variables) do
      {
        invitationToken: invited_agent.raw_invitation_token,
        password: "newpassword123",
        passwordConfirmation: "different"
      }
    end

    it "returns validation error" do
      result = execute_graphql(query: query, variables: variables)

      data = result["data"]["acceptInvite"]
      expect(data["agent"]).to be_nil
      expect(data["errors"]).not_to be_empty
    end
  end

  describe "with invalid token" do
    let(:variables) do
      {
        invitationToken: "invalid-token",
        password: "newpassword123",
        passwordConfirmation: "newpassword123"
      }
    end

    it "returns error" do
      result = execute_graphql(query: query, variables: variables)

      data = result["data"]["acceptInvite"]
      expect(data["agent"]).to be_nil
      expect(data["errors"]).not_to be_empty
    end
  end
end
