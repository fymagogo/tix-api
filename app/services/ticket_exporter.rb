# frozen_string_literal: true

require "csv"

class TicketExporter
  SYNC_THRESHOLD = ENV.fetch("EXPORT_SYNC_THRESHOLD", 1).to_i

  def self.generate(tickets)
    CSV.generate(headers: true) do |csv|
      csv << [
        "ID",
        "Subject",
        "Description",
        "Status",
        "Customer Name",
        "Customer Email",
        "Assigned Agent",
        "Created At",
        "Closed At",
        "Comments Count",
      ]

      tickets.includes(:customer, :assigned_agent, :comments).find_each do |ticket|
        csv << [
          ticket.id,
          ticket.subject,
          ticket.description.truncate(200),
          ticket.status,
          ticket.customer.name,
          ticket.customer.email,
          ticket.assigned_agent&.name,
          ticket.created_at.iso8601,
          ticket.closed_at&.iso8601,
          ticket.comments.count,
        ]
      end
    end
  end

  def self.sync_threshold
    SYNC_THRESHOLD
  end
end
