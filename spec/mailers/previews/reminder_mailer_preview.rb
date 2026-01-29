# frozen_string_literal: true

# Preview emails at http://localhost:3000/rails/mailers/reminder_mailer
class ReminderMailerPreview < ActionMailer::Preview
  def open_tickets_digest
    agent = Agent.first || FactoryBot.create(:agent)
    tickets = agent.assigned_tickets.where(status: [:open, :in_progress])

    # If no tickets, create some sample data for preview
    if tickets.empty?
      customer = Customer.first || FactoryBot.create(:customer)
      tickets = [
        Ticket.new(
          id: 1,
          ticket_number: "TKT-000001",
          subject: "Sample urgent issue",
          status: :open,
          priority: :high,
          created_at: 2.days.ago,
          customer: customer
        ),
        Ticket.new(
          id: 2,
          ticket_number: "TKT-000002",
          subject: "Another pending request",
          status: :in_progress,
          priority: :medium,
          created_at: 1.day.ago,
          customer: customer
        )
      ]
    end

    ReminderMailer.open_tickets_digest(agent, tickets)
  end
end
