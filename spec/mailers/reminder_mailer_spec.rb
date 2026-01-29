# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReminderMailer, type: :mailer do
  describe "#open_tickets_digest" do
    let(:agent) { create(:agent, name: "John Doe", email: "john@example.com") }
    let(:customer) { create(:customer, name: "Jane Customer") }
    let!(:ticket1) { create(:ticket, subject: "First Issue", customer: customer, assigned_agent: agent, status: "in_progress") }
    let!(:ticket2) { create(:ticket, subject: "Second Issue", customer: customer, assigned_agent: agent, status: "hold") }

    let(:tickets) { Ticket.where(id: [ticket1.id, ticket2.id]) }
    let(:mail) { described_class.open_tickets_digest(agent, tickets) }

    it "sends to the agent's email" do
      expect(mail.to).to eq(["john@example.com"])
    end

    it "includes ticket count in subject" do
      expect(mail.subject).to eq("Daily Reminder: You have 2 open tickets")
    end

    it "uses singular ticket when only one" do
      single_ticket = Ticket.where(id: ticket1.id)
      single_mail = described_class.open_tickets_digest(agent, single_ticket)
      expect(single_mail.subject).to eq("Daily Reminder: You have 1 open ticket")
    end

    it "includes agent name in body" do
      expect(mail.body.encoded).to include("John Doe")
    end

    it "includes ticket subjects in body" do
      expect(mail.body.encoded).to include("First Issue")
      expect(mail.body.encoded).to include("Second Issue")
    end

    it "includes customer name in body" do
      expect(mail.body.encoded).to include("Jane Customer")
    end

    it "includes ticket numbers in body" do
      expect(mail.body.encoded).to include(ticket1.ticket_number)
      expect(mail.body.encoded).to include(ticket2.ticket_number)
    end

    it "renders both HTML and text parts" do
      expect(mail.parts.map(&:content_type)).to include(
        a_string_matching(/text\/html/),
        a_string_matching(/text\/plain/)
      )
    end
  end
end
