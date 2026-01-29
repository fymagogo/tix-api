# frozen_string_literal: true

module Mutations
  class AddComment < BaseMutation
    description "Add a comment to a ticket"

    argument :attachment_ids, [String], required: false, description: "Signed blob IDs from direct upload"
    argument :body, String, required: true
    argument :ticket_id, ID, required: true

    field :comment, Types::CommentType, null: true
    field :errors, [Types::ErrorType], null: false

    def resolve(ticket_id:, body:, attachment_ids: [])
      authenticate!

      ticket = Ticket.find(ticket_id)
      authorize!(ticket, :show?)

      comment = ticket.comments.build(body: body, author: current_user)
      authorize!(comment, :create?)

      # Attach files from signed blob IDs
      if attachment_ids.present?
        blobs = attachment_ids.map { |id| ActiveStorage::Blob.find_signed(id) }.compact
        comment.attachments.attach(blobs)
      end

      if comment.save
        { comment: comment, errors: [] }
      else
        { comment: nil, errors: format_errors(comment) }
      end
    rescue ActiveRecord::RecordNotFound
      { comment: nil, errors: [{ field: "ticket_id", message: "Ticket not found", code: "NOT_FOUND" }] }
    end

    private

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.message, code: "VALIDATION_ERROR" }
      end
    end
  end
end
