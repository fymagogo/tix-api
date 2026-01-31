# frozen_string_literal: true

RSpec.describe TicketExporter do
  describe ".generate" do
    let(:customer) { create(:customer) }
    let(:agent) { create(:agent) }
    let!(:ticket1) { create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "First ticket") }
    let!(:ticket2) { create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "Second ticket") }

    it "generates CSV with default headers" do
      csv = described_class.generate(Ticket.closed)
      lines = csv.split("\n")

      # Default fields: id, subject, status, customer_name, assigned_agent, created_at, closed_at
      expect(lines.first).to include("ID", "Subject", "Status", "Customer Name", "Assigned Agent")
    end

    it "includes all closed tickets" do
      csv = described_class.generate(Ticket.closed)

      expect(csv).to include("First ticket")
      expect(csv).to include("Second ticket")
    end

    it "includes ticket data" do
      csv = described_class.generate(Ticket.closed)

      expect(csv).to include(customer.name)
      expect(csv).to include(agent.name)
    end

    context "with custom fields" do
      it "generates CSV with only specified fields" do
        csv = described_class.generate(Ticket.closed, fields: ["id", "subject", "customer_email"])
        lines = csv.split("\n")

        expect(lines.first).to eq("ID,Subject,Customer Email")
        expect(csv).to include(customer.email)
      end

      it "includes all available fields when requested" do
        csv = described_class.generate(Ticket.closed, fields: described_class::AVAILABLE_FIELDS.keys)
        lines = csv.split("\n")

        expect(lines.first).to include("ID", "Subject", "Description", "Status", "Customer Name",
                                       "Customer Email", "Assigned Agent", "Created At", "Closed At", "Comments Count",)
      end
    end
  end

  describe "::SYNC_THRESHOLD" do
    it "defaults to 1 when ENV not set" do
      expect(described_class::SYNC_THRESHOLD).to eq(ENV.fetch("EXPORT_SYNC_THRESHOLD", 1).to_i)
    end
  end

  describe ".sync_threshold" do
    it "returns the SYNC_THRESHOLD constant" do
      expect(described_class.sync_threshold).to eq(described_class::SYNC_THRESHOLD)
    end
  end

  describe ".available_fields" do
    it "returns the list of available field keys" do
      expect(described_class.available_fields).to include("id", "subject", "customer_email", "status")
    end
  end

  describe ".default_fields" do
    it "returns the default field keys" do
      expect(described_class.default_fields).to eq(["id", "subject", "status", "customer_name", "assigned_agent",
                                                    "created_at", "closed_at",])
    end
  end
end
