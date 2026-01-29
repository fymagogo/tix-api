# frozen_string_literal: true

module Types
  class StatusChangeType < Types::BaseObject
    description "A status change record from audit log"

    field :from, String, null: true
    field :to, String, null: false
    field :changed_at, GraphQL::Types::ISO8601DateTime, null: false
    field :changed_by, Types::CommentAuthorUnion, null: true
  end
end
