# frozen_string_literal: true

module Types
  module Enums
    class TicketSortFieldEnum < Types::BaseEnum
      description "Fields to sort tickets by"

      value "CREATED_AT", value: :created_at
      value "UPDATED_AT", value: :updated_at
      value "STATUS", value: :status
      value "SUBJECT", value: :subject
    end
  end
end
