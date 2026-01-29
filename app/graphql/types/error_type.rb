# frozen_string_literal: true

module Types
  class ErrorType < Types::BaseObject
    description "A user-facing error"

    field :code, String, null: false, description: "Machine-readable error code"
    field :field, String, null: true, description: "Which field caused the error (null for base errors)"
    field :message, String, null: false, description: "Human-readable error message"
  end
end
