# frozen_string_literal: true

RSpec.describe Mutations::AddComment, type: :graphql do
  let(:query) do
    <<~GQL
      mutation AddComment($ticketId: ID!, $body: String!) {
        addComment(ticketId: $ticketId, body: $body) {
          comment {
            id
            body
            author {
              ... on Agent { id name }
              ... on Customer { id name }
            }
          }
          errors { field message code }
        }
      }
    GQL
  end

  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

  describe "agent adding comment" do
    let(:variables) { { ticketId: ticket.id, body: "Agent response" } }

    it "creates comment successfully" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["addComment"]
      expect(data["comment"]["body"]).to eq("Agent response")
      expect(data["errors"]).to be_empty
    end

    it "allows agent to be first to comment" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      expect(result["data"]["addComment"]["comment"]).to be_present
    end
  end

  describe "customer adding comment" do
    context "after agent has commented" do
      before { create(:comment, ticket: ticket, author: agent, body: "Agent first") }
      let(:variables) { { ticketId: ticket.id, body: "Customer reply" } }

      it "allows customer to comment" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

        data = result["data"]["addComment"]
        expect(data["comment"]["body"]).to eq("Customer reply")
        expect(data["errors"]).to be_empty
      end
    end

    context "before agent has commented" do
      let(:variables) { { ticketId: ticket.id, body: "Customer first comment" } }

      it "returns not authorized error" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

        # Policy check fails because customer cannot comment before agent
        expect(result["errors"].first["message"]).to eq("Not authorized")
      end
    end

    context "on another customer's ticket" do
      let(:other_customer) { create(:customer) }
      let(:variables) { { ticketId: ticket.id, body: "Unauthorized" } }

      it "returns not authorized error" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: other_customer })

        expect(result["errors"].first["message"]).to eq("Not authorized")
      end
    end
  end

  describe "without authentication" do
    let(:variables) { { ticketId: ticket.id, body: "Test" } }

    it "returns authentication error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: nil })

      expect(result["errors"].first["message"]).to eq("Authentication required")
    end
  end

  describe "non-existent ticket" do
    let(:variables) { { ticketId: "non-existent-uuid", body: "Test" } }

    it "returns not found error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["addComment"]
      expect(data["comment"]).to be_nil
      expect(data["errors"].first["code"]).to eq("NOT_FOUND")
    end
  end

  describe "validation errors" do
    let(:variables) { { ticketId: ticket.id, body: "" } }

    it "returns validation error for empty body" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      data = result["data"]["addComment"]
      expect(data["comment"]).to be_nil
      expect(data["errors"]).not_to be_empty
      expect(data["errors"].first["field"]).to eq("body")
    end
  end
end
