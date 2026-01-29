# frozen_string_literal: true

module Mutations
  class TransitionTicket < BaseMutation
    description "Transition a ticket to a new status"

    argument :event, String, required: true,
                             description: "AASM event: 'assign_agent', 'start_progress', 'put_on_hold', 'resume', 'close'"
    argument :ticket_id, ID, required: true

    field :errors, [Types::ErrorType], null: false
    field :ticket, Types::TicketType, null: true

    ALLOWED_EVENTS = ["assign_agent", "start_progress", "put_on_hold", "resume", "close"].freeze

    def resolve(ticket_id:, event:)
      authenticate!

      ticket = Ticket.find(ticket_id)
      authorize!(ticket, :transition?)

      unless ALLOWED_EVENTS.include?(event)
        return { ticket: nil, errors: [{ field: "event", message: "Invalid event", code: "INVALID_EVENT" }] }
      end

      if ticket.send("may_#{event}?")
        ticket.send("#{event}!")
        { ticket: ticket, errors: [] }
      else
        { ticket: nil,
          errors: [{ field: "status", message: "Cannot #{event} from current status", code: "INVALID_TRANSITION" }], }
      end
    rescue ActiveRecord::RecordNotFound
      { ticket: nil, errors: [{ field: "ticket_id", message: "Ticket not found", code: "NOT_FOUND" }] }
    end
  end
end
