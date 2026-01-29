# frozen_string_literal: true

RSpec.describe Resolvers::TicketsResolver, type: :graphql do
  let(:query) do
    <<~GQL
      query Tickets($pagination: PaginationInput, $filter: TicketFilterInput, $orderBy: TicketOrderByInput) {
        tickets(pagination: $pagination, filter: $filter, orderBy: $orderBy) {
          items {
            id
            subject
            status
            ticketNumber
          }
          pageInfo {
            currentPage
            totalPages
            totalCount
            hasNextPage
            hasPreviousPage
            perPage
          }
        }
      }
    GQL
  end

  let(:customer) { create(:customer) }
  let(:other_customer) { create(:customer) }
  let(:agent) { create(:agent) }

  describe "authorization" do
    context "as customer" do
      let!(:own_ticket) { create(:ticket, customer: customer, subject: "My ticket") }
      let!(:other_ticket) { create(:ticket, customer: other_customer, subject: "Other ticket") }

      it "returns only own tickets" do
        execute_graphql(query: query, context: { current_user: customer })

        items = graphql_data["tickets"]["items"]
        expect(items.length).to eq(1)
        expect(items.first["subject"]).to eq("My ticket")
      end
    end

    context "as agent" do
      let!(:ticket1) { create(:ticket, customer: customer) }
      let!(:ticket2) { create(:ticket, customer: other_customer) }

      it "returns all tickets" do
        execute_graphql(query: query, context: { current_user: agent })

        items = graphql_data["tickets"]["items"]
        expect(items.length).to eq(2)
      end
    end

    context "without authentication" do
      it "raises not authorized error" do
        execute_graphql(query: query, context: { current_user: nil })

        expect(graphql_errors).to be_present
      end
    end
  end

  describe "pagination" do
    let!(:tickets) { create_list(:ticket, 15, customer: customer) }

    it "returns first page by default" do
      execute_graphql(query: query, context: { current_user: agent })

      page_info = graphql_data["tickets"]["pageInfo"]
      expect(page_info["currentPage"]).to eq(1)
      expect(page_info["totalCount"]).to eq(15)
    end

    it "supports custom page size" do
      variables = { pagination: { page: 1, perPage: 5 } }
      execute_graphql(query: query, variables: variables, context: { current_user: agent })

      items = graphql_data["tickets"]["items"]
      page_info = graphql_data["tickets"]["pageInfo"]
      expect(items.length).to eq(5)
      expect(page_info["totalPages"]).to eq(3)
      expect(page_info["hasNextPage"]).to be true
    end

    it "supports page navigation" do
      variables = { pagination: { page: 2, perPage: 5 } }
      execute_graphql(query: query, variables: variables, context: { current_user: agent })

      page_info = graphql_data["tickets"]["pageInfo"]
      expect(page_info["currentPage"]).to eq(2)
      expect(page_info["hasPreviousPage"]).to be true
      expect(page_info["hasNextPage"]).to be true
    end
  end

  describe "filtering" do
    let!(:new_ticket) { create(:ticket, customer: customer, status: "new", subject: "New ticket") }
    let!(:in_progress_ticket) { create(:ticket, :in_progress, customer: customer, assigned_agent: agent, subject: "In progress") }
    let!(:closed_ticket) { create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "Closed") }

    context "by status" do
      it "filters by status" do
        variables = { filter: { status: "IN_PROGRESS" } }
        execute_graphql(query: query, variables: variables, context: { current_user: agent })

        items = graphql_data["tickets"]["items"]
        expect(items.length).to eq(1)
        expect(items.first["status"]).to eq("in_progress")
      end
    end

    context "by assigned_to_me" do
      let(:other_agent) { create(:agent) }
      let!(:other_agent_ticket) { create(:ticket, :in_progress, customer: customer, assigned_agent: other_agent) }

      it "filters to tickets assigned to current agent" do
        variables = { filter: { assignedToMe: true } }
        execute_graphql(query: query, variables: variables, context: { current_user: agent })

        items = graphql_data["tickets"]["items"]
        expect(items.all? { |t| Ticket.find(t["id"]).assigned_agent_id == agent.id }).to be true
      end
    end

    context "by search" do
      it "searches by subject" do
        variables = { filter: { search: "progress" } }
        execute_graphql(query: query, variables: variables, context: { current_user: agent })

        items = graphql_data["tickets"]["items"]
        expect(items.length).to eq(1)
        expect(items.first["subject"]).to include("progress")
      end

      it "searches by ticket number" do
        variables = { filter: { search: new_ticket.ticket_number } }
        execute_graphql(query: query, variables: variables, context: { current_user: agent })

        items = graphql_data["tickets"]["items"]
        expect(items.length).to eq(1)
        expect(items.first["ticketNumber"]).to eq(new_ticket.ticket_number)
      end
    end

    context "by date range" do
      it "filters by created_after" do
        variables = { filter: { createdAfter: 1.day.ago.iso8601 } }
        execute_graphql(query: query, variables: variables, context: { current_user: agent })

        expect(graphql_data["tickets"]["items"]).to be_present
      end

      it "filters by created_before" do
        variables = { filter: { createdBefore: 1.day.from_now.iso8601 } }
        execute_graphql(query: query, variables: variables, context: { current_user: agent })

        expect(graphql_data["tickets"]["items"]).to be_present
      end
    end
  end

  describe "ordering" do
    let!(:older_ticket) { create(:ticket, customer: customer, created_at: 2.days.ago) }
    let!(:newer_ticket) { create(:ticket, customer: customer, created_at: 1.day.ago) }

    it "orders by updated_at desc by default" do
      execute_graphql(query: query, context: { current_user: agent })

      items = graphql_data["tickets"]["items"]
      expect(items.first["id"]).to eq(newer_ticket.id)
    end

    it "supports custom ordering" do
      variables = { orderBy: { field: "CREATED_AT", direction: "ASC" } }
      execute_graphql(query: query, variables: variables, context: { current_user: agent })

      items = graphql_data["tickets"]["items"]
      expect(items.first["id"]).to eq(older_ticket.id)
    end
  end
end
