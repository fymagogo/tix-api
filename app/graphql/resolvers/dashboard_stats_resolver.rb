# frozen_string_literal: true

module Resolvers
  class DashboardStatsResolver < BaseResolver
    type Types::DashboardStatsType, null: false
    description "Get dashboard statistics (admin only)"

    def resolve
      authorize :agent, :admin?

      today = Time.current.beginning_of_day
      week_start = Time.current.beginning_of_week

      # Calculate average resolution time from audits
      closed_tickets_with_times = calculate_resolution_times

      {
        total_tickets: Ticket.count,
        open_tickets: Ticket.open.count,
        closed_tickets: Ticket.closed.count,
        unassigned_tickets: Ticket.where(assigned_agent_id: nil).count,
        tickets_by_status: tickets_by_status,
        tickets_by_priority: tickets_by_priority,
        average_resolution_time_hours: average_resolution_time(closed_tickets_with_times),
        tickets_created_today: Ticket.where("created_at >= ?", today).count,
        tickets_closed_today: tickets_closed_since(today),
        tickets_created_this_week: Ticket.where("created_at >= ?", week_start).count,
        tickets_closed_this_week: tickets_closed_since(week_start)
      }
    end

    private

    def authorize(record, action)
      unless context[:current_agent]&.admin?
        raise GraphQL::ExecutionError, "Not authorized"
      end
    end

    def tickets_by_status
      Ticket.group(:status).count.map do |status, count|
        { status: status, count: count }
      end
    end

    def tickets_by_priority
      Ticket.group(:priority).count.map do |priority, count|
        { priority: priority || "normal", count: count }
      end
    end

    def tickets_closed_since(time)
      Audited::Audit
        .where(auditable_type: "Ticket")
        .where("audited_changes -> 'status' ->> 1 = ?", "closed")
        .where("created_at >= ?", time)
        .count
    end

    def calculate_resolution_times
      # Get tickets that have been closed
      closed_tickets = Ticket.closed.includes(:audits)

      closed_tickets.filter_map do |ticket|
        closed_audit = ticket.audits
          .where("audited_changes -> 'status' ->> 1 = ?", "closed")
          .order(:created_at)
          .last

        next unless closed_audit

        {
          created_at: ticket.created_at,
          closed_at: closed_audit.created_at
        }
      end
    end

    def average_resolution_time(times)
      return nil if times.empty?

      total_hours = times.sum do |t|
        (t[:closed_at] - t[:created_at]) / 1.hour
      end

      (total_hours / times.count).round(2)
    end
  end
end
