# frozen_string_literal: true

module Mutations
  class ExportClosedTickets < BaseMutation
    description "Export closed tickets to CSV (agents only)"

    argument :filter, Types::Inputs::TicketFilterInputType, required: false

    field :async, Boolean, null: false, description: "True if export will be emailed"
    field :csv, String, null: true, description: "CSV data (only for small exports)"
    field :errors, [Types::ErrorType], null: false

    def resolve(filter: nil)
      require_agent!

      # Build scope for closed tickets only
      scope = Ticket.closed
      scope = apply_filters(scope, filter) if filter

      count = scope.count
      threshold = TicketExporter::SYNC_THRESHOLD

      if count <= threshold
        csv_data = TicketExporter.generate(scope)
        { csv: csv_data, async: false, errors: [] }
      else
        # Queue async export job
        TicketExportJob.perform_later(current_user.id, filter&.to_h)
        { csv: nil, async: true, errors: [] }
      end
    end

    private

    def apply_filters(scope, filter)
      scope = scope.where(assigned_agent_id: current_user.id) if filter[:assigned_to_me]
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
end
