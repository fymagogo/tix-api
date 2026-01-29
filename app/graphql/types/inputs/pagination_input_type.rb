# frozen_string_literal: true

module Types
  module Inputs
    class PaginationInputType < Types::BaseInputObject
      description "Pagination parameters"

      MAX_PER_PAGE = 100

      argument :page, Integer, required: false, default_value: 1, description: "Page number (1-indexed)"
      argument :per_page, Integer, required: false, default_value: 20, description: "Items per page (max 100)"

      def prepare
        {
          page: [page, 1].max,
          per_page: [[per_page, 1].max, MAX_PER_PAGE].min,
        }
      end
    end
  end
end
