# frozen_string_literal: true

RSpec.describe Mutations::ExportClosedTickets, type: :graphql do
  let(:query) do
    <<~GQL
      mutation ExportClosedTickets($filter: TicketFilterInput) {
        exportClosedTickets(filter: $filter) {
          csv
          async
          errors { field message code }
        }
      }
    GQL
  end

  let(:agent) { create(:agent) }
  let(:admin) { create(:agent, :admin) }
  let(:customer) { create(:customer) }

  describe "as agent" do
    context "with small number of tickets (sync)" do
      let!(:closed_ticket) { create(:ticket, :closed, customer: customer, assigned_agent: agent) }

      it "returns CSV data synchronously" do
        result = execute_graphql(query: query, context: { current_user: agent })

        data = result["data"]["exportClosedTickets"]
        expect(data["csv"]).to be_present
        expect(data["async"]).to be false
        expect(data["errors"]).to be_empty
      end
    end

    context "with large number of tickets (async)" do
      before do
        stub_const("TicketExporter::SYNC_THRESHOLD", 2)
        create_list(:ticket, 3, :closed, customer: customer, assigned_agent: agent)
      end

      it "returns async true and queues job" do
        expect do
          result = execute_graphql(query: query, context: { current_user: agent })

          data = result["data"]["exportClosedTickets"]
          expect(data["csv"]).to be_nil
          expect(data["async"]).to be true
          expect(data["errors"]).to be_empty
        end.to have_enqueued_job(TicketExportJob)
      end
    end

    context "with filter" do
      let!(:own_ticket) { create(:ticket, :closed, customer: customer, assigned_agent: agent) }
      let(:other_agent) { create(:agent) }
      let!(:other_ticket) { create(:ticket, :closed, customer: customer, assigned_agent: other_agent) }

      it "filters by assigned_to_me" do
        result = execute_graphql(
          query: query,
          variables: { filter: { assignedToMe: true } },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["csv"]).to include(own_ticket.subject)
        expect(data["csv"]).not_to include(other_ticket.subject)
      end

      it "filters by customer_id" do
        other_customer = create(:customer)
        other_customer_ticket = create(:ticket, :closed, customer: other_customer, assigned_agent: agent)

        result = execute_graphql(
          query: query,
          variables: { filter: { customerId: customer.id } },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["csv"]).to include(own_ticket.subject)
        expect(data["csv"]).not_to include(other_customer_ticket.subject)
      end

      it "filters by search term" do
        result = execute_graphql(
          query: query,
          variables: { filter: { search: own_ticket.subject } },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["csv"]).to include(own_ticket.subject)
      end

      it "filters by date range" do
        result = execute_graphql(
          query: query,
          variables: { filter: { createdAfter: 1.day.ago.iso8601, createdBefore: 1.day.from_now.iso8601 } },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["async"]).to be false
      end
    end
  end

  describe "as customer" do
    it "returns agent access required error" do
      result = execute_graphql(query: query, context: { current_user: customer })

      expect(result["errors"].first["message"]).to eq("Agent access required")
    end
  end

  describe "without authentication" do
    it "returns authentication error" do
      result = execute_graphql(query: query, context: { current_user: nil })

      expect(result["errors"].first["message"]).to eq("Authentication required")
    end
  end
end
