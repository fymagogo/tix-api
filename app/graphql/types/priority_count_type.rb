# frozen_string_literal: true

module Types
  class PriorityCountType < Types::BaseObject
    description "Ticket count by priority"

    field :count, Integer, null: false
    field :priority, String, null: false
  end
end
