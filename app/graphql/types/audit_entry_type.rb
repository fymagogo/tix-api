# frozen_string_literal: true

module Types
  class AuditEntryType < Types::BaseObject
    description "An audit log entry recording a change to a record"

    field :id, ID, null: false
    field :action, String, null: false, description: "The type of action: create, update, or destroy"
    field :changes, [Types::AuditChangeType], null: false, description: "List of field changes"
    field :changed_at, GraphQL::Types::ISO8601DateTime, null: false, description: "When the change occurred"
    field :changed_by, Types::CommentAuthorUnion, null: true, description: "Who made the change"
    field :version, Int, null: false, description: "The version number of this record after this change"
  end
end
