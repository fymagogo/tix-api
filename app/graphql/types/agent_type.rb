# frozen_string_literal: true

module Types
  class AgentType < Types::BaseObject
    description "A support agent user"

    field :active_tickets, [Types::TicketType], null: false,
                                                description: "Tickets actively being worked on (not new or closed)"
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :email, String, null: false
    field :history, [Types::HistoryEventType], null: false, description: "Human-readable history events",
                                               method: :human_readable_history
    field :id, ID, null: false
    field :invitation_pending, Boolean, null: false, description: "Whether the agent has a pending invitation"
    field :invited_by, Types::AgentType, null: true
    field :is_admin, Boolean, null: false
    field :name, String, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def active_tickets
      object.assigned_tickets.active.order(updated_at: :desc)
    end

    # rubocop:disable Naming/PredicatePrefix
    def is_admin
      object.is_admin || false
    end
    # rubocop:enable Naming/PredicatePrefix

    # rubocop:disable Naming/PredicateMethod
    def invitation_pending
      object.invitation_token.present? && object.invitation_accepted_at.nil?
    end
    # rubocop:enable Naming/PredicateMethod
  end
end
