# frozen_string_literal: true

require "rails_helper"

RSpec.describe OpenTicketReminderJob, type: :job do
  describe "#perform" do
    let!(:agent_with_tickets) { create(:agent, name: "Agent With Tickets") }
    let!(:agent_without_tickets) { create(:agent, name: "Agent Without Tickets") }
    let!(:agent_with_closed_tickets) { create(:agent, name: "Agent With Closed Tickets") }

    let!(:customer) { create(:customer) }

    let!(:open_ticket1) do
      create(:ticket, customer: customer, assigned_agent: agent_with_tickets, status: "in_progress")
    end

    let!(:open_ticket2) do
      create(:ticket, customer: customer, assigned_agent: agent_with_tickets, status: "hold")
    end

    let!(:closed_ticket) do
      ticket = create(:ticket, customer: customer, assigned_agent: agent_with_closed_tickets, status: "in_progress")
      ticket.close!
      ticket
    end

    it "sends emails only to agents with open tickets" do
      expect(ReminderMailer).to receive(:open_tickets_digest)
        .with(agent_with_tickets, kind_of(ActiveRecord::Relation))
        .and_return(double(deliver_now: true))

      expect(ReminderMailer).not_to receive(:open_tickets_digest)
        .with(agent_without_tickets, anything)

      expect(ReminderMailer).not_to receive(:open_tickets_digest)
        .with(agent_with_closed_tickets, anything)

      described_class.new.perform
    end

    it "includes all open tickets for the agent" do
      allow(ReminderMailer).to receive(:open_tickets_digest) do |agent, tickets|
        expect(agent).to eq(agent_with_tickets)
        expect(tickets.count).to eq(2)
        expect(tickets).to include(open_ticket1, open_ticket2)
        double(deliver_now: true)
      end

      described_class.new.perform
    end

    it "orders tickets by created_at ascending" do
      allow(ReminderMailer).to receive(:open_tickets_digest) do |_agent, tickets|
        expect(tickets.first.created_at).to be <= tickets.last.created_at
        double(deliver_now: true)
      end

      described_class.new.perform
    end

    it "enqueues in the mailers queue" do
      expect(described_class.new.queue_name).to eq("mailers")
    end
  end
end
