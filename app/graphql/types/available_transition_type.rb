# frozen_string_literal: true

module Types
  class AvailableTransitionType < Types::BaseObject
    description "An available state transition for a ticket"

    field :event, String, null: false, description: "The AASM event name to trigger"
    field :label, String, null: false, description: "Human-readable label for the transition"
  end
end
