# frozen_string_literal: true

module Types
  module Enums
    class SortDirectionEnum < Types::BaseEnum
      description "Sort direction"

      value "ASC", value: :asc
      value "DESC", value: :desc
    end
  end
end
