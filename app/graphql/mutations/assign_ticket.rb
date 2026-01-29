# frozen_string_literal: true

module Mutations
  class AssignTicket < BaseMutation
    description "Manually assign a ticket to an agent (admin only)"

    argument :ticket_id, ID, required: true
    argument :agent_id, ID, required: true

    field :ticket, Types::TicketType, null: true
    field :errors, [Types::ErrorType], null: false

    def resolve(ticket_id:, agent_id:)
      require_admin!

      ticket = Ticket.find(ticket_id)
      agent = Agent.find(agent_id)

      ActiveRecord::Base.transaction do
        ticket.assigned_agent = agent
        ticket.assign_agent! if ticket.may_assign_agent?
        ticket.save!
        agent.touch(:last_assigned_at)
      end

      { ticket: ticket, errors: [] }
    rescue ActiveRecord::RecordNotFound => e
      { ticket: nil, errors: [{ field: "base", message: e.message, code: "NOT_FOUND" }] }
    rescue ActiveRecord::RecordInvalid => e
      { ticket: nil, errors: format_errors(e.record) }
    end

    private

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.message, code: "VALIDATION_ERROR" }
      end
    end
  end
end
