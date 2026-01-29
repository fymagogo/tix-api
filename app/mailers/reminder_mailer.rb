# frozen_string_literal: true

class ReminderMailer < ApplicationMailer
  def open_tickets_digest(agent, tickets)
    @agent = agent
    @tickets = tickets
    @ticket_count = tickets.count

    mail(
      to: agent.email,
      subject: "Daily Reminder: You have #{@ticket_count} open #{'ticket'.pluralize(@ticket_count)}"
    )
  end
end
