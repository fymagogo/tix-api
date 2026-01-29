# frozen_string_literal: true

module Types
  class StatusCountType < Types::BaseObject
    description "Ticket count by status"

    field :count, Integer, null: false
    field :status, String, null: false
  end
end
