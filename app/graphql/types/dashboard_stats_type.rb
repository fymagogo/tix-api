# frozen_string_literal: true

module Types
  class DashboardStatsType < Types::BaseObject
    description "Dashboard statistics for admin overview"

    field :total_tickets, Integer, null: false
    field :open_tickets, Integer, null: false
    field :closed_tickets, Integer, null: false
    field :unassigned_tickets, Integer, null: false
    field :tickets_by_status, [Types::StatusCountType], null: false
    field :average_resolution_time_hours, Float, null: true
    field :tickets_created_today, Integer, null: false
    field :tickets_closed_today, Integer, null: false
    field :tickets_created_this_week, Integer, null: false
    field :tickets_closed_this_week, Integer, null: false
  end
end
