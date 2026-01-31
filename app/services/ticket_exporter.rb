# frozen_string_literal: true

require "csv"

class TicketExporter
  SYNC_THRESHOLD = ENV.fetch("EXPORT_SYNC_THRESHOLD", 1).to_i

  # All available fields for export
  AVAILABLE_FIELDS = {
    "id" => { header: "ID", value: ->(t) { t.id } },
    "subject" => { header: "Subject", value: ->(t) { t.subject } },
    "description" => { header: "Description", value: ->(t) { t.description.truncate(200) } },
    "status" => { header: "Status", value: ->(t) { t.status } },
    "customer_name" => { header: "Customer Name", value: ->(t) { t.customer.name } },
    "customer_email" => { header: "Customer Email", value: ->(t) { t.customer.email } },
    "assigned_agent" => { header: "Assigned Agent", value: ->(t) { t.assigned_agent&.name } },
    "created_at" => { header: "Created At", value: ->(t) { t.created_at.iso8601 } },
    "closed_at" => { header: "Closed At", value: ->(t) { t.closed_at&.iso8601 } },
    "comments_count" => { header: "Comments Count", value: ->(t) { t.comments.count } },
  }.freeze

  # Default fields for export (sensible subset)
  DEFAULT_FIELDS = [
    "id",
    "subject",
    "status",
    "customer_name",
    "assigned_agent",
    "created_at",
    "closed_at",
  ].freeze

  def self.generate(tickets, fields: DEFAULT_FIELDS)
    selected_fields = fields.map { |f| AVAILABLE_FIELDS[f] }.compact

    CSV.generate(headers: true) do |csv|
      csv << selected_fields.map { |f| f[:header] }

      tickets.includes(:customer, :assigned_agent, :comments).find_each do |ticket|
        csv << selected_fields.map { |f| f[:value].call(ticket) }
      end
    end
  end

  def self.sync_threshold
    SYNC_THRESHOLD
  end

  def self.available_fields
    AVAILABLE_FIELDS.keys
  end

  def self.default_fields
    DEFAULT_FIELDS
  end
end
