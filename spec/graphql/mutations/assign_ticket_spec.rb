# frozen_string_literal: true

RSpec.describe Mutations::AssignTicket, type: :graphql do
  let(:query) do
    <<~GQL
      mutation AssignTicket($ticketId: ID!, $agentId: ID!) {
        assignTicket(ticketId: $ticketId, agentId: $agentId) {
          ticket {
            id
            status
            assignedAgent { id name }
          }
          errors { field message code }
        }
      }
    GQL
  end

  let(:admin) { create(:agent, :admin) }
  let(:agent) { create(:agent) }
  let(:customer) { create(:customer) }
  let(:ticket) { create(:ticket, customer: customer) }

  describe "admin assigning ticket" do
    let(:variables) { { ticketId: ticket.id, agentId: agent.id } }

    it "assigns ticket to agent" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["assignTicket"]
      expect(data["ticket"]["assignedAgent"]["id"]).to eq(agent.id)
      expect(data["ticket"]["status"]).to eq("agent_assigned")
      expect(data["errors"]).to be_empty
    end

    it "updates agent last_assigned_at" do
      expect {
        execute_graphql(query: query, variables: variables, context: { current_user: admin })
      }.to change { agent.reload.last_assigned_at }
    end
  end

  describe "non-admin agent attempting to assign" do
    let(:variables) { { ticketId: ticket.id, agentId: agent.id } }

    it "returns admin access required error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      expect(result["errors"].first["message"]).to eq("Admin access required")
    end
  end

  describe "customer attempting to assign" do
    let(:variables) { { ticketId: ticket.id, agentId: agent.id } }

    it "returns agent access required error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

      expect(result["errors"].first["message"]).to eq("Agent access required")
    end
  end

  describe "non-existent ticket" do
    let(:variables) { { ticketId: "non-existent-uuid", agentId: agent.id } }

    it "returns not found error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["assignTicket"]
      expect(data["ticket"]).to be_nil
      expect(data["errors"].first["code"]).to eq("NOT_FOUND")
    end
  end

  describe "non-existent agent" do
    let(:variables) { { ticketId: ticket.id, agentId: "non-existent-uuid" } }

    it "returns not found error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["assignTicket"]
      expect(data["ticket"]).to be_nil
      expect(data["errors"].first["code"]).to eq("NOT_FOUND")
    end
  end

  describe "reassigning ticket" do
    let(:original_agent) { create(:agent) }
    let(:new_agent) { create(:agent) }
    let(:assigned_ticket) { create(:ticket, :with_agent, customer: customer, assigned_agent: original_agent) }
    let(:variables) { { ticketId: assigned_ticket.id, agentId: new_agent.id } }

    it "reassigns to new agent" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

      data = result["data"]["assignTicket"]
      expect(data["ticket"]["assignedAgent"]["id"]).to eq(new_agent.id)
    end
  end
end
