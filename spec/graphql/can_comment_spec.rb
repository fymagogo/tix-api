# frozen_string_literal: true

require "rails_helper"

RSpec.describe "TicketType#canComment", type: :graphql do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent, status: "in_progress") }

  let(:query) do
    <<~GQL
      query Ticket($id: ID!) {
        ticket(id: $id) {
          id
          canComment
        }
      }
    GQL
  end

  describe "for agents" do
    context "when ticket is not closed" do
      it "returns true" do
        execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: agent })
        expect(graphql_data.dig("ticket", "canComment")).to be true
      end
    end

    context "when ticket is closed" do
      before { ticket.close! }

      it "returns false" do
        execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: agent })
        expect(graphql_data.dig("ticket", "canComment")).to be false
      end
    end
  end

  describe "for customers" do
    context "when no agent has commented" do
      it "returns false" do
        execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: customer })
        expect(graphql_data.dig("ticket", "canComment")).to be false
      end
    end

    context "when an agent has commented" do
      before { create(:comment, ticket: ticket, author: agent) }

      it "returns true" do
        execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: customer })
        expect(graphql_data.dig("ticket", "canComment")).to be true
      end
    end

    context "when ticket is closed (even with agent comment)" do
      before do
        create(:comment, ticket: ticket, author: agent)
        ticket.close!
      end

      it "returns false" do
        execute_graphql(query: query, variables: { id: ticket.id }, context: { current_user: customer })
        expect(graphql_data.dig("ticket", "canComment")).to be false
      end
    end
  end

  describe "without current_user" do
    it "returns nil (unauthorized)" do
      execute_graphql(query: query, variables: { id: ticket.id }, context: {})
      # Without authentication, ticket is not accessible
      expect(graphql_data["ticket"]).to be_nil
    end
  end
end
