# frozen_string_literal: true

RSpec.describe Mutations::CreateTicket, type: :graphql do
  let(:query) do
    <<~GQL
      mutation CreateTicket($subject: String!, $description: String!) {
        createTicket(subject: $subject, description: $description) {
          ticket {
            id
            subject
            description
            status
            ticketNumber
          }
          errors { field message code }
        }
      }
    GQL
  end

  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }

  describe "authenticated as customer" do
    let(:variables) { { subject: "Help needed", description: "I need assistance with my account" } }

    it "creates a ticket" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

      data = result["data"]["createTicket"]
      expect(data["ticket"]["subject"]).to eq("Help needed")
      expect(data["ticket"]["description"]).to eq("I need assistance with my account")
      expect(data["ticket"]["status"]).to eq("new")
      expect(data["ticket"]["ticketNumber"]).to be_present
      expect(data["errors"]).to be_empty
    end

    it "assigns ticket to customer" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

      ticket_id = result["data"]["createTicket"]["ticket"]["id"]
      expect(Ticket.find(ticket_id).customer).to eq(customer)
    end
  end

  describe "authenticated as agent" do
    let(:variables) { { subject: "Test", description: "Test description" } }

    it "returns customer access required error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: agent })

      expect(result["errors"].first["message"]).to eq("Customer access required")
      expect(result["errors"].first["extensions"]["code"]).to eq("UNAUTHORIZED")
    end
  end

  describe "without authentication" do
    let(:variables) { { subject: "Test", description: "Test description" } }

    it "returns authentication error" do
      result = execute_graphql(query: query, variables: variables, context: { current_user: nil })

      expect(result["errors"].first["message"]).to eq("Authentication required")
      expect(result["errors"].first["extensions"]["code"]).to eq("UNAUTHENTICATED")
    end
  end

  describe "validation errors" do
    context "missing subject" do
      let(:variables) { { subject: "", description: "Valid description" } }

      it "returns validation error" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

        data = result["data"]["createTicket"]
        expect(data["ticket"]).to be_nil
        expect(data["errors"]).not_to be_empty
      end
    end

    context "missing description" do
      let(:variables) { { subject: "Valid subject", description: "" } }

      it "returns validation error" do
        result = execute_graphql(query: query, variables: variables, context: { current_user: customer })

        data = result["data"]["createTicket"]
        expect(data["ticket"]).to be_nil
        expect(data["errors"]).not_to be_empty
      end
    end
  end
end
