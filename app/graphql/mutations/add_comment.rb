# frozen_string_literal: true

module Mutations
  class AddComment < BaseMutation
    description "Add a comment to a ticket"

    argument :attachment_ids, [String], required: false, description: "Signed blob IDs from direct upload"
    argument :body, String, required: true
    argument :ticket_id, ID, required: true

    field :comment, Types::CommentType, null: true

    def execute(ticket_id:, body:, attachment_ids: [])
      ticket = Ticket.find(ticket_id)
      authorize!(ticket, :show?)

      comment = ticket.comments.build(body: body, author: current_user)
      authorize!(comment, :create?)

      # Attach files from signed blob IDs
      if attachment_ids.present?
        blobs = attachment_ids.map { |id| ActiveStorage::Blob.find_signed(id) }.compact
        comment.attachments.attach(blobs)
      end

      comment.save!
      { comment: comment }
    end
  end
end
