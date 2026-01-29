# frozen_string_literal: true

module Mutations
  class CreateTicket < BaseMutation
    description "Create a new support ticket (customers only)"

    argument :attachment_ids, [String], required: false, description: "Signed blob IDs from direct upload"
    argument :description, String, required: true
    argument :subject, String, required: true

    field :errors, [Types::ErrorType], null: false
    field :ticket, Types::TicketType, null: true

    def resolve(subject:, description:, attachment_ids: [])
      require_customer!

      ticket = current_user.tickets.build(subject: subject, description: description)

      # Attach files from signed blob IDs
      if attachment_ids.present?
        blobs = attachment_ids.map { |id| ActiveStorage::Blob.find_signed(id) }.compact
        ticket.attachments.attach(blobs)
      end

      if ticket.save
        { ticket: ticket, errors: [] }
      else
        { ticket: nil, errors: format_errors(ticket) }
      end
    end

    private

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.message, code: "VALIDATION_ERROR" }
      end
    end
  end
end
