# frozen_string_literal: true

module Mutations
  class TransitionTicket < BaseMutation
    description "Transition a ticket to a new status"

    argument :event, String, required: true, description: "AASM event name"
    argument :ticket_id, ID, required: true

    field :errors, [Types::ErrorType], null: false
    field :ticket, Types::TicketType, null: true

    def resolve(ticket_id:, event:)
      authenticate!

      ticket = Ticket.find(ticket_id)
      authorize!(ticket, :transition?)

      if ticket.send("may_#{event}?")
        ticket.send("#{event}!")
        { ticket: ticket, errors: [] }
      else
        { ticket: nil,
          errors: [{ field: "status", message: "Cannot #{event} from current status", code: "INVALID_TRANSITION" }], }
      end
    rescue NoMethodError
      { ticket: nil, errors: [{ field: "event", message: "Invalid event", code: "INVALID_EVENT" }] }
    rescue ActiveRecord::RecordNotFound
      { ticket: nil, errors: [{ field: "ticket_id", message: "Ticket not found", code: "NOT_FOUND" }] }
    end
  end
end
