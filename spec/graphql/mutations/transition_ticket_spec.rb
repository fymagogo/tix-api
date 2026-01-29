# frozen_string_literal: true

RSpec.describe Mutations::TransitionTicket, type: :graphql do
  let(:query) do
    <<~GQL
      mutation TransitionTicket($ticketId: ID!, $event: String!) {
        transitionTicket(ticketId: $ticketId, event: $event) {
          ticket {
            id
            status
          }
          errors { field message code }
        }
      }
    GQL
  end

  let(:agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }
  let(:customer) { create(:customer) }

  describe "valid transitions" do
    let(:ticket) { create(:ticket, assigned_agent: agent) }

    context "assign_agent" do
      let(:variables) { { ticketId: ticket.id, event: "assign_agent" } }

      it "transitions from new to agent_assigned" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

        data = result["data"]["transitionTicket"]
        expect(data["ticket"]["status"]).to eq("agent_assigned")
        expect(data["errors"]).to be_empty
      end
    end

    context "start_progress" do
      let(:ticket) { create(:ticket, :with_agent, assigned_agent: agent) }
      let(:variables) { { ticketId: ticket.id, event: "start_progress" } }

      it "transitions from agent_assigned to in_progress" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

        data = result["data"]["transitionTicket"]
        expect(data["ticket"]["status"]).to eq("in_progress")
        expect(data["errors"]).to be_empty
      end
    end

    context "put_on_hold" do
      let(:ticket) { create(:ticket, :in_progress, assigned_agent: agent) }
      let(:variables) { { ticketId: ticket.id, event: "put_on_hold" } }

      it "transitions from in_progress to hold" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

        data = result["data"]["transitionTicket"]
        expect(data["ticket"]["status"]).to eq("hold")
      end
    end

    context "resume" do
      let(:ticket) { create(:ticket, :on_hold, assigned_agent: agent) }
      let(:variables) { { ticketId: ticket.id, event: "resume" } }

      it "transitions from hold to in_progress" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

        data = result["data"]["transitionTicket"]
        expect(data["ticket"]["status"]).to eq("in_progress")
      end
    end

    context "close" do
      let(:ticket) { create(:ticket, :in_progress, assigned_agent: agent) }
      let(:variables) { { ticketId: ticket.id, event: "close" } }

      it "transitions from in_progress to closed" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

        data = result["data"]["transitionTicket"]
        expect(data["ticket"]["status"]).to eq("closed")
      end
    end
  end

  describe "invalid event" do
    let(:ticket) { create(:ticket, assigned_agent: agent) }
    let(:variables) { { ticketId: ticket.id, event: "invalid_event" } }

    it "returns error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["transitionTicket"]
      expect(data["ticket"]).to be_nil
      expect(data["errors"].first["code"]).to eq("INVALID_EVENT")
    end
  end

  describe "invalid transition" do
    let(:ticket) { create(:ticket, assigned_agent: agent) }
    let(:variables) { { ticketId: ticket.id, event: "close" } }

    it "returns error for close from new status" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["transitionTicket"]
      expect(data["ticket"]).to be_nil
      expect(data["errors"].first["code"]).to eq("INVALID_TRANSITION")
    end
  end

  describe "authorization" do
    let(:other_agent) { create(:agent) }
    let(:ticket) { create(:ticket, assigned_agent: agent) }
    let(:variables) { { ticketId: ticket.id, event: "assign_agent" } }

    context "non-assigned agent (not admin)" do
      it "returns not authorized error" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: other_agent })

        expect(result["errors"].first["message"]).to eq("Not authorized")
      end
    end

    context "admin can transition any ticket" do
      it "allows admin to transition" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: admin })

        data = result["data"]["transitionTicket"]
        expect(data["ticket"]["status"]).to eq("agent_assigned")
      end
    end

    context "customer cannot transition" do
      it "returns not authorized error" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

        expect(result["errors"].first["message"]).to eq("Not authorized")
      end
    end
  end

  describe "ticket not found" do
    let(:variables) { { ticketId: "non-existent-uuid", event: "assign_agent" } }

    it "returns not found error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["transitionTicket"]
      expect(data["errors"].first["code"]).to eq("NOT_FOUND")
    end
  end
end
