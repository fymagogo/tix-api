# frozen_string_literal: true

module Types
  class CustomerType < Types::BaseObject
    description "A customer user"

    field :id, ID, null: false
    field :email, String, null: false
    field :name, String, null: false
    field :tickets, [Types::TicketType], null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def tickets
      object.tickets.order(updated_at: :desc)
    end
  end
end
