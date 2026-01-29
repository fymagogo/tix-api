# frozen_string_literal: true

RSpec.describe TicketExporter do
  describe ".generate" do
    let(:customer) { create(:customer) }
    let(:agent) { create(:agent) }
    let!(:ticket1) { create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "First ticket") }
    let!(:ticket2) { create(:ticket, :closed, customer: customer, assigned_agent: agent, subject: "Second ticket") }

    it "generates CSV with headers" do
      csv = described_class.generate(Ticket.closed)
      lines = csv.split("\n")
      
      expect(lines.first).to include("ID", "Subject", "Status", "Customer Email")
    end

    it "includes all closed tickets" do
      csv = described_class.generate(Ticket.closed)
      
      expect(csv).to include("First ticket")
      expect(csv).to include("Second ticket")
    end

    it "includes ticket data" do
      csv = described_class.generate(Ticket.closed)
      
      expect(csv).to include(customer.email)
      expect(csv).to include(agent.name)
    end
  end

  describe "::SYNC_THRESHOLD" do
    it "is set to 100" do
      expect(described_class::SYNC_THRESHOLD).to eq(100)
    end
  end

  describe ".sync_threshold" do
    it "returns the SYNC_THRESHOLD constant" do
      expect(described_class.sync_threshold).to eq(described_class::SYNC_THRESHOLD)
    end
  end
end
