# frozen_string_literal: true

module Types
  module Inputs
    class TicketOrderByInputType < Types::BaseInputObject
      description "Sorting parameters for tickets"

      argument :direction, Types::Enums::SortDirectionEnum, required: false, default_value: :desc,
                                                            description: "Sort direction"
      argument :field, Types::Enums::TicketSortFieldEnum, required: true, description: "Field to sort by"
    end
  end
end
