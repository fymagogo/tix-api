# frozen_string_literal: true

module Types
  class StatusCountType < Types::BaseObject
    description "Ticket count by status"

    field :status, String, null: false
    field :count, Integer, null: false
  end
end
