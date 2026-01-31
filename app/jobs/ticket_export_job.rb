# frozen_string_literal: true

class TicketExportJob < ApplicationJob
  queue_as :exports

  def perform(agent_id, filter = nil, closed_after: nil, closed_before: nil, fields: nil, filename: nil)
    agent = Agent.find(agent_id)

    scope = Ticket.closed
    scope = apply_filters(scope, filter) if filter.present?
    scope = scope.where(closed_at: Time.iso8601(closed_after)..) if closed_after.present?
    scope = scope.where(closed_at: ..Time.iso8601(closed_before)) if closed_before.present?

    selected_fields = fields.presence || TicketExporter::DEFAULT_FIELDS
    csv_data = TicketExporter.generate(scope, fields: selected_fields)

    export_filename = filename || "closed-tickets-#{Date.current.iso8601}.csv"

    ExportMailer.closed_tickets(agent, csv_data, filename: export_filename).deliver_now
  end

  private

  def apply_filters(scope, filter)
    filter = filter.symbolize_keys if filter.respond_to?(:symbolize_keys)

    if filter[:assigned_to_me]
      scope = scope.where(assigned_agent_id: filter[:assigned_to_me] ? Agent.find_by(id: filter[:agent_id])&.id : nil)
    end
    scope = scope.where(customer_id: filter[:customer_id]) if filter[:customer_id].present?
    if filter[:search].present?
      search_term = filter[:search].to_s.strip[0, 100]
      search_term = ActiveRecord::Base.sanitize_sql_like(search_term)
      scope = scope.where("subject ILIKE ?", "%#{search_term}%")
    end
    scope = scope.where(created_at: (filter[:created_after])..) if filter[:created_after].present?
    scope = scope.where(created_at: ..(filter[:created_before])) if filter[:created_before].present?
    scope
  end
end
