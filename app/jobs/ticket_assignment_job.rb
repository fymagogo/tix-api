# frozen_string_literal: true

class TicketAssignmentJob < ApplicationJob
  queue_as :ticket_assignment

  def perform(ticket_id)
    ticket = Ticket.find_by(id: ticket_id)
    return unless ticket
    return if ticket.assigned_agent.present?

    agent = Agent.next_for_assignment
    return unless agent

    ActiveRecord::Base.transaction do
      ticket.update!(assigned_agent: agent)
      ticket.assign_agent! if ticket.may_assign_agent?
      agent.touch(:last_assigned_at)
    end
  rescue AASM::InvalidTransition => e
    Rails.logger.error("TicketAssignmentJob failed for ticket #{ticket_id}: #{e.message}")
  end
end
