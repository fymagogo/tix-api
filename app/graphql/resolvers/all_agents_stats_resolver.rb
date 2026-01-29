# frozen_string_literal: true

module Resolvers
  class AllAgentsStatsResolver < BaseResolver
    type [Types::AgentStatsType], null: false
    description "Get statistics for all agents (admin only)"

    def resolve
      raise GraphQL::ExecutionError, "Not authorized" unless context[:current_agent]&.admin?

      week_start = Time.current.beginning_of_week
      month_start = Time.current.beginning_of_month

      Agent.all.map do |agent|
        assigned_tickets = Ticket.where(assigned_agent_id: agent.id)

        {
          agent: agent,
          assigned_tickets: assigned_tickets.count,
          open_tickets: assigned_tickets.open.count,
          closed_tickets: assigned_tickets.closed.count,
          closed_this_week: tickets_closed_by_agent_since(agent, week_start),
          closed_this_month: tickets_closed_by_agent_since(agent, month_start),
          average_resolution_time_hours: average_resolution_time(agent),
        }
      end
    end

    private

    def tickets_closed_by_agent_since(agent, time)
      Audited::Audit
        .where(auditable_type: "Ticket")
        .where(user_type: "Agent", user_id: agent.id)
        .where("audited_changes -> 'status' ->> 1 = ?", "closed")
        .where(created_at: time..)
        .count
    end

    def average_resolution_time(agent)
      closed_tickets = Ticket.closed.where(assigned_agent_id: agent.id).includes(:audits)

      times = closed_tickets.filter_map do |ticket|
        closed_audit = ticket.audits
          .where("audited_changes -> 'status' ->> 1 = ?", "closed")
          .order(:created_at)
          .last

        next unless closed_audit

        (closed_audit.created_at - ticket.created_at) / 1.hour
      end

      return nil if times.empty?

      (times.sum / times.count).round(2)
    end
  end
end
