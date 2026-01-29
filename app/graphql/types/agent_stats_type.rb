# frozen_string_literal: true

module Types
  class AgentStatsType < Types::BaseObject
    description "Statistics for a specific agent"

    field :agent, Types::AgentType, null: false
    field :assigned_tickets, Integer, null: false
    field :open_tickets, Integer, null: false
    field :closed_tickets, Integer, null: false
    field :closed_this_week, Integer, null: false
    field :closed_this_month, Integer, null: false
    field :average_resolution_time_hours, Float, null: true
  end
end
