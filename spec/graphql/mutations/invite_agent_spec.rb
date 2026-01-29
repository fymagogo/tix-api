# frozen_string_literal: true

RSpec.describe Mutations::InviteAgent, type: :graphql do
  let(:query) do
    <<~GQL
      mutation InviteAgent($email: String!, $name: String!, $isAdmin: Boolean) {
        inviteAgent(email: $email, name: $name, isAdmin: $isAdmin) {
          agent {
            id
            email
            name
            isAdmin
          }
          errors { field message code }
        }
      }
    GQL
  end

  let(:admin) { create(:agent, :admin) }
  let(:agent) { create(:agent) }
  let(:customer) { create(:customer) }

  describe "admin inviting agent" do
    let(:variables) { { email: "newagent@tix.test", name: "New Agent", isAdmin: false } }

    it "creates invitation" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["inviteAgent"]
      expect(data["agent"]["email"]).to eq("newagent@tix.test")
      expect(data["agent"]["name"]).to eq("New Agent")
      expect(data["agent"]["isAdmin"]).to be false
      expect(data["errors"]).to be_empty
    end

    it "can invite as admin" do
      variables[:isAdmin] = true
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["inviteAgent"]
      expect(data["agent"]["isAdmin"]).to be true
    end
  end

  describe "non-admin attempting to invite" do
    let(:variables) { { email: "newagent@tix.test", name: "New Agent" } }

    it "returns admin access required error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["inviteAgent"]
      expect(data["errors"].first["message"]).to eq("Admin access required")
    end
  end

  describe "customer attempting to invite" do
    let(:variables) { { email: "newagent@tix.test", name: "New Agent" } }

    it "returns agent access required error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

      data = result["data"]["inviteAgent"]
      expect(data["errors"].first["message"]).to eq("Agent access required")
    end
  end

  describe "duplicate email" do
    let!(:existing_agent) { create(:agent, email: "existing@tix.test") }
    let(:variables) { { email: "existing@tix.test", name: "Duplicate" } }

    it "returns validation error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["inviteAgent"]
      expect(data["agent"]).to be_nil
      expect(data["errors"]).not_to be_empty
    end
  end
end
