# frozen_string_literal: true

RSpec.describe Mutations::ExportClosedTickets, type: :graphql do
  let(:query) do
    <<~GQL
      mutation ExportClosedTickets(
        $filter: TicketFilterInput
        $closedAfter: ISO8601DateTime
        $closedBefore: ISO8601DateTime
        $fields: [String!]
      ) {
        exportClosedTickets(
          filter: $filter
          closedAfter: $closedAfter
          closedBefore: $closedBefore
          fields: $fields
        ) {
          csv
          async
          filename
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

    context "with closed date range" do
      let!(:recent_ticket) do
        create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "Recent ticket").tap do |t|
          t.update_column(:closed_at, 3.days.ago)
        end
      end
      let!(:old_ticket) do
        create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "Old ticket").tap do |t|
          t.update_column(:closed_at, 30.days.ago)
        end
      end

      it "filters by closedAfter" do
        result = execute_graphql(
          query: query,
          variables: { closedAfter: 7.days.ago.iso8601 },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["csv"]).to include("Recent ticket")
        expect(data["csv"]).not_to include("Old ticket")
      end

      it "filters by closedBefore" do
        result = execute_graphql(
          query: query,
          variables: { closedBefore: 7.days.ago.iso8601 },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["csv"]).not_to include("Recent ticket")
        expect(data["csv"]).to include("Old ticket")
      end

      it "includes date range in filename" do
        result = execute_graphql(
          query: query,
          variables: {
            closedAfter: 30.days.ago.beginning_of_day.iso8601,
            closedBefore: Time.current.end_of_day.iso8601,
          },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["filename"]).to match(/closed-tickets-\d{8}-to-\d{8}\.csv/)
      end

      it "uses 'all-time' in filename when no date range specified" do
        result = execute_graphql(
          query: query,
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["filename"]).to eq("closed-tickets-all-time.csv")
      end
    end

    context "with custom fields" do
      let!(:closed_ticket) { create(:ticket, :closed, customer: customer, assigned_agent: agent) }

      it "exports only specified fields" do
        result = execute_graphql(
          query: query,
          variables: { fields: ["id", "subject", "customer_email"] },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        csv_lines = data["csv"].split("\n")
        expect(csv_lines.first).to eq("ID,Subject,Customer Email")
        expect(data["csv"]).to include(customer.email)
      end

      it "returns error for invalid fields" do
        result = execute_graphql(
          query: query,
          variables: { fields: ["id", "invalid_field"] },
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        expect(data["errors"].first["message"]).to include("Invalid fields: invalid_field")
      end

      it "uses default fields when not specified" do
        result = execute_graphql(
          query: query,
          context: { current_user: agent },
        )

        data = result["data"]["exportClosedTickets"]
        csv_lines = data["csv"].split("\n")
        expect(csv_lines.first).to include("ID", "Subject", "Status", "Customer Name", "Assigned Agent")
        expect(csv_lines.first).not_to include("Customer Email")
      end
    end
  end

  describe "as customer" do
    it "returns agent access required error" do
      result = execute_graphql(query: query, context: { current_user: customer })

      data = result["data"]["exportClosedTickets"]
      expect(data["errors"].first["message"]).to eq("Agent access required")
    end
  end

  describe "without authentication" do
    it "returns authentication error" do
      result = execute_graphql(query: query, context: { current_user: nil })

      data = result["data"]["exportClosedTickets"]
      expect(data["errors"].first["message"]).to eq("Authentication required")
    end
  end
end
