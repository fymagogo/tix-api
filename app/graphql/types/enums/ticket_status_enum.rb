# frozen_string_literal: true

module Types
  module Enums
    class TicketStatusEnum < Types::BaseEnum
      description "Possible ticket statuses"

      value "NEW", value: "new"
      value "AGENT_ASSIGNED", value: "agent_assigned"
      value "IN_PROGRESS", value: "in_progress"
      value "HOLD", value: "hold"
      value "CLOSED", value: "closed"
    end
  end
end
