# frozen_string_literal: true

module Mutations
  class AssignTicket < BaseMutation
    requires_role :agent

    description "Assign or reassign a ticket to an agent"

    argument :agent_id, ID, required: true
    argument :ticket_id, ID, required: true

    field :ticket, Types::TicketType, null: true

    def execute(ticket_id:, agent_id:)
      ticket = Ticket.find(ticket_id)
      authorize!(ticket, :reassign?)

      agent = Agent.find(agent_id)

      ticket.assigned_agent = agent
      ticket.assign_agent! if ticket.may_assign_agent?
      ticket.save!
      agent.touch(:last_assigned_at)

      { ticket: ticket }
    end
  end
end
