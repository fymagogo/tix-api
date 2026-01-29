# frozen_string_literal: true

class TicketExportJob < ApplicationJob
  queue_as :exports

  def perform(agent_id, filter = nil)
    agent = Agent.find(agent_id)

    scope = Ticket.closed
    scope = apply_filters(scope, filter) if filter.present?

    csv_data = TicketExporter.generate(scope)

    ExportMailer.closed_tickets(agent, csv_data).deliver_now
  end

  private

  def apply_filters(scope, filter)
    filter = filter.symbolize_keys if filter.respond_to?(:symbolize_keys)

    scope = scope.where(assigned_agent_id: filter[:assigned_to_me] ? Agent.find_by(id: filter[:agent_id])&.id : nil) if filter[:assigned_to_me]
    scope = scope.where(customer_id: filter[:customer_id]) if filter[:customer_id].present?
    scope = scope.where("subject ILIKE ?", "%#{filter[:search]}%") if filter[:search].present?
    scope = scope.where("created_at >= ?", filter[:created_after]) if filter[:created_after].present?
    scope = scope.where("created_at <= ?", filter[:created_before]) if filter[:created_before].present?
    scope
  end
end
