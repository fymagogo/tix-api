# frozen_string_literal: true

RSpec.describe "Agent Workflow Integration", type: :graphql do
  let(:agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }
  let(:customer) { create(:customer) }

  describe "agent ticket management workflow" do
    let!(:unassigned_tickets) { create_list(:ticket, 3, customer: customer) }
    let!(:assigned_ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

    it "allows agent to view tickets and admin to assign them" do
      # Step 1: View all tickets
      tickets_query = <<~GQL
        query Tickets {
          tickets {
            items { id subject status assignedAgent { id } }
            pageInfo { totalCount }
          }
        }
      GQL

      result = execute_graphql(
        query: tickets_query,
        context: { current_user: agent },
      )

      items = result.dig("data", "tickets", "items")
      expect(items.length).to eq(4)

      # Step 2: Admin claims a ticket for the agent
      ticket_to_claim = unassigned_tickets.first
      assign_query = <<~GQL
        mutation AssignTicket($ticketId: ID!, $agentId: ID!) {
          assignTicket(ticketId: $ticketId, agentId: $agentId) {
            ticket { id assignedAgent { id name } status }
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: assign_query,
        variables: { ticketId: ticket_to_claim.id, agentId: agent.id },
        context: { current_user: admin },
      )

      expect(result.dig("data", "assignTicket", "ticket", "assignedAgent", "id")).to eq(agent.id)

      # Step 3: View "my tickets" only using filter
      my_tickets_query = <<~GQL
        query Tickets($filter: TicketFilterInput) {
          tickets(filter: $filter) {
            items { id assignedAgent { id } }
            pageInfo { totalCount }
          }
        }
      GQL

      result = execute_graphql(
        query: my_tickets_query,
        variables: { filter: { assignedToMe: true } },
        context: { current_user: agent },
      )

      my_tickets = result.dig("data", "tickets", "items")
      expect(my_tickets.length).to eq(2) # original assigned + newly claimed
      expect(my_tickets.all? { |t| t["assignedAgent"]["id"] == agent.id }).to be true
    end
  end

  describe "ticket search and filtering" do
    before do
      create(:ticket, :with_agent, customer: customer, subject: "Login problem", assigned_agent: agent)
      create(:ticket, :with_agent, customer: customer, subject: "Payment issue", assigned_agent: agent)
      create(:ticket, customer: customer, subject: "General question")
    end

    it "allows searching tickets by keyword" do
      search_query = <<~GQL
        query Tickets($filter: TicketFilterInput) {
          tickets(filter: $filter) {
            items { id subject }
          }
        }
      GQL

      result = execute_graphql(
        query: search_query,
        variables: { filter: { search: "login" } },
        context: { current_user: agent },
      )

      subjects = result.dig("data", "tickets", "items").pluck("subject")
      expect(subjects).to contain_exactly("Login problem")
    end

    it "allows filtering by status" do
      # Create tickets with different statuses
      create(:ticket, :in_progress, customer: customer, assigned_agent: agent)
      create(:ticket, :closed, customer: customer, assigned_agent: agent)

      status_query = <<~GQL
        query Tickets($filter: TicketFilterInput) {
          tickets(filter: $filter) {
            items { id status }
          }
        }
      GQL

      result = execute_graphql(
        query: status_query,
        variables: { filter: { status: "IN_PROGRESS" } },
        context: { current_user: agent, current_agent: agent },
      )

      tickets = result.dig("data", "tickets", "items")
      expect(tickets.length).to eq(1)
      expect(tickets.first["status"]).to eq("in_progress")
    end

    it "allows combining multiple filters" do
      combined_query = <<~GQL
        query Tickets($filter: TicketFilterInput) {
          tickets(filter: $filter) {
            items { id subject status assignedAgent { id } }
          }
        }
      GQL

      result = execute_graphql(
        query: combined_query,
        variables: { filter: { assignedToMe: true, status: "AGENT_ASSIGNED" } },
        context: { current_user: agent, current_agent: agent },
      )

      tickets = result.dig("data", "tickets", "items")
      expect(tickets.length).to eq(2)
      expect(tickets.all? { |t| t["status"] == "agent_assigned" }).to be true
    end
  end

  describe "bulk ticket operations" do
    let!(:tickets) do
      3.times.map { create(:ticket, :in_progress, customer: customer, assigned_agent: agent) }
    end

    it "allows agent to close multiple tickets in sequence" do
      transition_query = <<~GQL
        mutation TransitionTicket($ticketId: ID!, $event: String!) {
          transitionTicket(ticketId: $ticketId, event: $event) {
            ticket { id status }
            errors { field message }
          }
        }
      GQL

      tickets.each do |ticket|
        result = execute_graphql(
          query: transition_query,
          variables: { ticketId: ticket.id, event: "close" },
          context: { current_user: agent },
        )

        expect(result.dig("data", "transitionTicket", "ticket", "status")).to eq("closed")
      end

      # Verify all are closed
      expect(tickets.map(&:reload).map(&:status).uniq).to eq(["closed"])
    end
  end

  describe "agent ticket export" do
    let!(:closed_tickets) { create_list(:ticket, 3, :closed, customer: customer, assigned_agent: agent) }
    let!(:open_ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

    it "allows agent to export closed tickets" do
      export_query = <<~GQL
        mutation ExportClosedTickets {
          exportClosedTickets {
            csv
            async
            errors { field message }
          }
        }
      GQL

      result = execute_graphql(
        query: export_query,
        context: { current_user: agent, current_agent: agent },
      )

      export_result = result.dig("data", "exportClosedTickets")
      expect(export_result).to be_present
      expect(export_result["csv"]).to be_present # Should return CSV for small exports
      expect(export_result["async"]).to be false
    end
  end

  describe "ticket detail with comments" do
    let(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

    before do
      ticket.assign_agent!
      ticket.start_progress!
      create(:comment, ticket: ticket, author: agent, body: "Working on this")
      create(:comment, ticket: ticket, author: customer, body: "Thanks!")
    end

    it "returns full ticket detail with comments" do
      detail_query = <<~GQL
        query Ticket($id: ID!) {
          ticket(id: $id) {
            id
            subject
            status
            ticketNumber
            customer { id name email }
            assignedAgent { id name }
            comments {
              id
              body
              createdAt
              author {
                ... on Agent { id name }
                ... on Customer { id name }
              }
            }
          }
        }
      GQL

      result = execute_graphql(
        query: detail_query,
        variables: { id: ticket.id },
        context: { current_user: agent, current_agent: agent },
      )

      ticket_data = result.dig("data", "ticket")
      expect(ticket_data["status"]).to eq("in_progress")
      expect(ticket_data["comments"].length).to eq(2)
    end
  end

  describe "agent views ticket by number" do
    let!(:ticket) { create(:ticket, customer: customer, assigned_agent: agent) }

    it "allows viewing ticket by ticket number" do
      by_number_query = <<~GQL
        query TicketByNumber($ticketNumber: String!) {
          ticketByNumber(ticketNumber: $ticketNumber) {
            id
            ticketNumber
            subject
          }
        }
      GQL

      result = execute_graphql(
        query: by_number_query,
        variables: { ticketNumber: ticket.ticket_number },
        context: { current_user: agent },
      )

      expect(result.dig("data", "ticketByNumber", "id")).to eq(ticket.id)
    end
  end
end
