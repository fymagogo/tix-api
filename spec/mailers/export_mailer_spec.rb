# frozen_string_literal: true

RSpec.describe ExportMailer, type: :mailer do
  describe "#closed_tickets" do
    let(:agent) { create(:agent, email: "agent@tix.test") }
    let(:csv_data) { "ID,Subject,Status\n1,Test,closed" }
    let(:mail) { described_class.closed_tickets(agent, csv_data) }

    it "sends to the agent's email" do
      expect(mail.to).to eq(["agent@tix.test"])
    end

    it "has the correct subject" do
      expect(mail.subject).to eq("Your closed tickets export is ready")
    end

    it "attaches the CSV file" do
      expect(mail.attachments.length).to eq(1)
      expect(mail.attachments.first.filename).to include("closed_tickets_")
      expect(mail.attachments.first.filename).to end_with(".csv")
    end

    it "includes CSV content in attachment" do
      attachment = mail.attachments.first
      expect(attachment.body.decoded).to eq(csv_data)
    end
  end
end
