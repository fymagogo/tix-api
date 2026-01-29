# frozen_string_literal: true

RSpec.describe "Ticket Lifecycle Integration", type: :graphql do
  let(:customer) { create(:customer) }
  let(:agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }

  describe "complete ticket lifecycle from creation to closure" do
    it "handles full ticket journey" do
      # Step 1: Customer creates a ticket
      create_ticket_query = <<~GQL
        mutation CreateTicket($subject: String!, $description: String!) {
          createTicket(subject: $subject, description: $description) {
            ticket { id ticketNumber subject status }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: create_ticket_query,
        variables: { subject: "Cannot login", description: "Getting error on login page" },
        context: { current_user: customer },
      )

      ticket_data = result.dig("data", "createTicket", "ticket")
      expect(ticket_data["status"]).to eq("new")
      expect(ticket_data["ticketNumber"]).to be_present
      ticket_id = ticket_data["id"]

      # Step 2: Admin assigns agent to ticket
      assign_query = <<~GQL
        mutation AssignTicket($ticketId: ID!, $agentId: ID!) {
          assignTicket(ticketId: $ticketId, agentId: $agentId) {
            ticket { id status assignedAgent { id name } }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: assign_query,
        variables: { ticketId: ticket_id, agentId: agent.id },
        context: { current_user: admin },
      )

      expect(result.dig("data", "assignTicket", "ticket", "assignedAgent", "id")).to eq(agent.id)

      # Step 3: Agent transitions to in_progress
      transition_query = <<~GQL
        mutation TransitionTicket($ticketId: ID!, $event: String!) {
          transitionTicket(ticketId: $ticketId, event: $event) {
            ticket { id status }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket_id, event: "start_progress" },
        context: { current_user: agent },
      )

      expect(result.dig("data", "transitionTicket", "ticket", "status")).to eq("in_progress")

      # Step 4: Agent adds a comment
      add_comment_query = <<~GQL
        mutation AddComment($ticketId: ID!, $body: String!) {
          addComment(ticketId: $ticketId, body: $body) {
            comment { id body author { ... on Agent { name } } }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: add_comment_query,
        variables: { ticketId: ticket_id, body: "Please try clearing your browser cache." },
        context: { current_user: agent },
      )

      expect(result.dig("data", "addComment", "comment", "body")).to eq("Please try clearing your browser cache.")

      # Step 5: Customer replies to the comment
      result = execute_graphql(
        query: add_comment_query,
        variables: { ticketId: ticket_id, body: "That worked, thank you!" },
        context: { current_user: customer },
      )

      expect(result.dig("data", "addComment", "comment", "body")).to eq("That worked, thank you!")

      # Step 6: Agent closes the ticket
      result = execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket_id, event: "close" },
        context: { current_user: agent },
      )

      expect(result.dig("data", "transitionTicket", "ticket", "status")).to eq("closed")

      # Step 7: Verify final ticket state
      ticket_query = <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) {
            id
            status
            ticketNumber
            comments { id body }
          }
        }
      GQL

      result = execute_graphql(
        query: ticket_query,
        variables: { id: ticket_id },
        context: { current_user: customer },
      )

      final_ticket = result.dig("data", "ticket")
      expect(final_ticket["status"]).to eq("closed")
      expect(final_ticket["comments"].length).to eq(2)
    end
  end

  describe "ticket with hold workflow" do
    let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

    before do
      ticket.assign_agent!
      ticket.start_progress!
    end

    it "handles hold and resume flow" do
      transition_query = <<~GQL
        mutation TransitionTicket($ticketId: ID!, $event: String!) {
          transitionTicket(ticketId: $ticketId, event: $event) {
            ticket { id status }
            errors { field message }
          }
        }
      GQL

      # Put on hold
      result = execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket.id, event: "put_on_hold" },
        context: { current_user: agent },
      )
      expect(result.dig("data", "transitionTicket", "ticket", "status")).to eq("hold")

      # Resume
      result = execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket.id, event: "resume" },
        context: { current_user: agent },
      )
      expect(result.dig("data", "transitionTicket", "ticket", "status")).to eq("in_progress")

      # Close from in_progress
      result = execute_graphql(
        query: transition_query,
        variables: { ticketId: ticket.id, event: "close" },
        context: { current_user: agent },
      )
      expect(result.dig("data", "transitionTicket", "ticket", "status")).to eq("closed")
    end
  end

  describe "customer viewing their tickets" do
    let!(:customer_ticket1) { create(:ticket, customer: customer, subject: "First issue") }
    let!(:customer_ticket2) { create(:ticket, customer: customer, subject: "Second issue") }
    let!(:other_customer_ticket) { create(:ticket, subject: "Other customer issue") }

    it "only shows customer their own tickets via ticket query" do
      # Customer can view their own ticket
      ticket_query = <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) { id subject }
        }
      GQL

      result = execute_graphql(
        query: ticket_query,
        variables: { id: customer_ticket1.id },
        context: { current_user: customer },
      )

      expect(result.dig("data", "ticket", "subject")).to eq("First issue")

      # Customer cannot view other customer's ticket
      result = execute_graphql(
        query: ticket_query,
        variables: { id: other_customer_ticket.id },
        context: { current_user: customer },
      )

      expect(result["errors"].first["message"]).to eq("Not authorized")
    end
  end

  describe "ticket reassignment" do
    let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }
    let(:other_agent) { create(:agent) }

    before { ticket.assign_agent! }

    it "allows admin to reassign ticket to another agent" do
      assign_query = <<~GQL
        mutation AssignTicket($ticketId: ID!, $agentId: ID!) {
          assignTicket(ticketId: $ticketId, agentId: $agentId) {
            ticket { assignedAgent { id name } }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: assign_query,
        variables: { ticketId: ticket.id, agentId: other_agent.id },
        context: { current_user: admin },
      )

      expect(result.dig("data", "assignTicket", "ticket", "assignedAgent", "id")).to eq(other_agent.id)
    end
  end
end
