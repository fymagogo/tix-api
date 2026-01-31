# frozen_string_literal: true

module Mutations
  class CreateTicket < BaseMutation
    requires_role :customer

    description "Create a new support ticket (customers only)"

    argument :attachment_ids, [String], required: false, description: "Signed blob IDs from direct upload"
    argument :description, String, required: true
    argument :subject, String, required: true

    field :ticket, Types::TicketType, null: true

    def execute(subject:, description:, attachment_ids: [])
      ticket = current_user.tickets.build(subject: subject, description: description)

      # Attach files from signed blob IDs
      if attachment_ids.present?
        blobs = attachment_ids.map { |id| ActiveStorage::Blob.find_signed(id) }.compact
        ticket.attachments.attach(blobs)
      end

      ticket.save!
      { ticket: ticket }
    end
  end
end
