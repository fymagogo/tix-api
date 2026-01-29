# frozen_string_literal: true

module Types
  module Inputs
    class TicketFilterInputType < Types::BaseInputObject
      description "Filter parameters for tickets"

      argument :assigned_to_me, Boolean, required: false, description: "Only show tickets assigned to current agent"
      argument :created_after, GraphQL::Types::ISO8601DateTime, required: false, description: "Created after date"
      argument :created_before, GraphQL::Types::ISO8601DateTime, required: false, description: "Created before date"
      argument :customer_id, ID, required: false, description: "Filter by customer ID"
      argument :search, String, required: false, description: "Search in subject or ticket number"
      argument :status, Types::Enums::TicketStatusEnum, required: false, description: "Filter by status"
    end
  end
end
