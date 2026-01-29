# frozen_string_literal: true

class TicketMailer < ApplicationMailer
  def status_changed(ticket, old_status, new_status)
    @ticket = ticket
    @customer = ticket.customer
    @old_status = old_status
    @new_status = new_status
    @agent = ticket.assigned_agent

    mail(
      to: @customer.email,
      subject: "Ticket ##{ticket.ticket_number} status updated to #{new_status.humanize}"
    )
  end

  def ticket_closed(ticket)
    @ticket = ticket
    @customer = ticket.customer
    @agent = ticket.assigned_agent

    mail(
      to: @customer.email,
      subject: "Ticket ##{ticket.ticket_number} has been resolved"
    )
  end
end
