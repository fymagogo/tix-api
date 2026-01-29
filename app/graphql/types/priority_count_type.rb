# frozen_string_literal: true

module Types
  class PriorityCountType < Types::BaseObject
    description "Ticket count by priority"

    field :priority, String, null: false
    field :count, Integer, null: false
  end
end
