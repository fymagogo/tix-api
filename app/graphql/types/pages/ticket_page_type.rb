# frozen_string_literal: true

module Types
  module Pages
    class TicketPageType < Types::BaseObject
      description "Paginated list of tickets"

      field :items, [Types::TicketType], null: false
      field :page_info, Types::PageInfoType, null: false
    end
  end
end
