# frozen_string_literal: true

module Types
  class HistoryEventType < Types::BaseObject
    description "A human-readable history event"

    field :actor, Types::CommentAuthorUnion, null: true, description: "Who performed the action"
    field :event, String, null: false, description: "Human-readable description of what happened"
    field :id, ID, null: false
    field :occurred_at, GraphQL::Types::ISO8601DateTime, null: false
  end
end
