# frozen_string_literal: true

module Mutations
  class ExportClosedTickets < BaseMutation
    requires_role :agent

    description "Export closed tickets to CSV (agents only)"

    argument :closed_after, GraphQL::Types::ISO8601DateTime, required: false,
                                                             description: "Filter tickets closed on or after this date"
    argument :closed_before, GraphQL::Types::ISO8601DateTime, required: false,
                                                              description: "Filter tickets closed on or before this date"
    argument :fields, [String], required: false,
                                description: "Fields to include in export (defaults to standard set)"
    argument :filter, Types::Inputs::TicketFilterInputType, required: false

    field :async, Boolean, null: true, description: "True if export will be emailed"
    field :csv, String, null: true, description: "CSV data (only for small exports)"
    field :filename, String, null: true, description: "Suggested filename for download"

    def execute(filter: nil, closed_after: nil, closed_before: nil, fields: nil)
      # Validate fields if provided
      if fields.present?
        invalid_fields = fields - TicketExporter::AVAILABLE_FIELDS.keys
        if invalid_fields.any?
          error!("Invalid fields: #{invalid_fields.join(', ')}", field: "fields", code: "INVALID_FIELDS")
        end
      end

      # Build scope for closed tickets only
      scope = Ticket.closed
      scope = apply_filters(scope, filter) if filter
      scope = scope.where(closed_at: closed_after..) if closed_after.present?
      scope = scope.where(closed_at: ..closed_before) if closed_before.present?

      count = scope.count
      threshold = TicketExporter::SYNC_THRESHOLD
      filename = generate_filename(closed_after, closed_before)
      selected_fields = fields.presence || TicketExporter::DEFAULT_FIELDS

      if count <= threshold
        csv_data = TicketExporter.generate(scope, fields: selected_fields)
        { csv: csv_data, async: false, filename: filename }
      else
        # Queue async export job
        TicketExportJob.perform_later(
          current_user.id,
          filter&.to_h,
          closed_after: closed_after&.iso8601,
          closed_before: closed_before&.iso8601,
          fields: selected_fields,
          filename: filename,
        )
        { csv: nil, async: true, filename: filename }
      end
    end

    private

    def generate_filename(closed_after, closed_before)
      parts = ["closed-tickets"]

      if closed_after.present? && closed_before.present?
        parts << closed_after.strftime("%Y%m%d")
        parts << "to"
        parts << closed_before.strftime("%Y%m%d")
      elsif closed_after.present?
        parts << "from"
        parts << closed_after.strftime("%Y%m%d")
      elsif closed_before.present?
        parts << "until"
        parts << closed_before.strftime("%Y%m%d")
      else
        parts << "all-time"
      end

      "#{parts.join('-')}.csv"
    end

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
