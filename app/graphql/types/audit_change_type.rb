# frozen_string_literal: true

module Types
  class AuditChangeType < Types::BaseObject
    description "A single field change in an audit entry"

    field :field, String, null: false, description: "The name of the field that changed"
    field :from, String, null: true, description: "The previous value (null for create)"
    field :to, String, null: true, description: "The new value"
  end
end
