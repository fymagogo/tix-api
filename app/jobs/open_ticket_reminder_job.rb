# frozen_string_literal: true

class OpenTicketReminderJob < ApplicationJob
  queue_as :mailers

  def perform
    # Find all agents with their open tickets preloaded
    agents_with_tickets = Agent
      .joins(:assigned_tickets)
      .where.not(tickets: { status: "closed" })
      .distinct

    agents_with_tickets.each do |agent|
      open_tickets = Ticket
        .where(assigned_agent_id: agent.id)
        .where.not(status: "closed")
        .includes(:customer)
        .order(created_at: :asc)
      ReminderMailer.open_tickets_digest(agent, open_tickets).deliver_now
    end
  end
end
