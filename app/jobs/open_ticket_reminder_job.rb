# frozen_string_literal: true

class OpenTicketReminderJob < ApplicationJob
  queue_as :mailers

  def perform
    # Find all agents who have at least one open ticket assigned
    agents_with_open_tickets.each do |agent|
      open_tickets = agent.assigned_tickets.where.not(status: "closed").order(created_at: :asc)
      ReminderMailer.open_tickets_digest(agent, open_tickets).deliver_now
    end
  end

  private

  def agents_with_open_tickets
    Agent.joins(:assigned_tickets)
         .where.not(tickets: { status: "closed" })
         .distinct
  end
end
