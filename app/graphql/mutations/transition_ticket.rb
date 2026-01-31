# frozen_string_literal: true

module Mutations
  class TransitionTicket < BaseMutation
    description "Transition a ticket to a new status"

    argument :event, String, required: true, description: "AASM event name"
    argument :ticket_id, ID, required: true

    field :ticket, Types::TicketType, null: true

    def execute(ticket_id:, event:)
      ticket = Ticket.find(ticket_id)
      authorize!(ticket, :transition?)

      error!("Invalid event", field: "event", code: "INVALID_EVENT") unless ticket.respond_to?("may_#{event}?")

      unless ticket.send("may_#{event}?")
        error!("Cannot #{event} from current status", field: "status", code: "INVALID_TRANSITION")
      end

      ticket.send("#{event}!")
      { ticket: ticket }
    end
  end
end
