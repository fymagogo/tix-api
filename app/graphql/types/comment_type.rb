# frozen_string_literal: true

module Types
  class CommentType < Types::BaseObject
    description "A comment on a ticket"

    field :id, ID, null: false
    field :body, String, null: false
    field :ticket, Types::TicketType, null: false
    field :author, Types::CommentAuthorUnion, null: false
    field :attachments, [Types::AttachmentType], null: false, description: "File attachments"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
