# frozen_string_literal: true

module Types
  class HistoryEventType < Types::BaseObject
    description "A human-readable history event"

    field :id, ID, null: false
    field :event, String, null: false, description: "Human-readable description of what happened"
    field :occurred_at, GraphQL::Types::ISO8601DateTime, null: false
    field :actor, Types::CommentAuthorUnion, null: true, description: "Who performed the action"
  end
end
