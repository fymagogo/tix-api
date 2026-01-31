# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    class MutationError < StandardError; end

    include Authenticatable

    argument_class Types::BaseArgument
    field_class Types::BaseField
    object_class Types::BaseObject

    field :errors, [Types::ErrorType], null: false

    def resolve(**args)
      # Check authentication/authorization first
      return serialize_with_errors({}) unless check_auth!

      ActiveRecord::Base.transaction do
        serialize_with_errors(execute(**args))
      end
    rescue MutationError
      serialize_with_errors({})
    rescue ActiveRecord::RecordInvalid => e
      serialize_with_errors(validation_error_response(e.record))
    rescue ActiveRecord::RecordNotFound
      error("Record not found", code: "NOT_FOUND")
      serialize_with_errors({})
    rescue Pundit::NotAuthorizedError
      error("Not authorized", code: "UNAUTHORIZED")
      serialize_with_errors({})
    rescue AASM::InvalidTransition => e
      error("Invalid status transition: #{e.message}", code: "INVALID_TRANSITION")
      serialize_with_errors({})
    rescue StandardError => e
      handle_unexpected_error(e)
    end

    # Subclasses implement this instead of resolve
    def execute(**_args)
      raise NotImplementedError, "Subclasses must implement execute"
    end

    # Pundit authorization helper
    def authorize!(record, action)
      policy = Pundit.policy!(current_user, record)
      error!("Not authorized", code: "UNAUTHORIZED") unless policy.public_send(action)
    end

    # Silent error - adds to errors array but continues execution
    def error(message, field: nil, code: nil)
      errors_array << { message: message, field: field, code: code }
      nil
    end

    # Raises and stops execution immediately
    def error!(message, field: nil, code: nil)
      errors_array << { message: message, field: field, code: code }
      raise MutationError, message
    end

    private

    def validation_error_response(record)
      record.errors.each do |error|
        errors_array << {
          message: error.full_message,
          field: error.attribute.to_s.camelize(:lower),
          code: "VALIDATION_ERROR",
        }
      end
      {}
    end

    def serialize_with_errors(payload)
      { **payload, errors: errors_array }
    end

    def errors_array
      @_errors ||= []
    end

    def handle_unexpected_error(error)
      raise GraphQL::ExecutionError, "#{error.class}: #{error.message}" unless Rails.env.production?

      Rails.logger.error("Mutation error: #{error.class} - #{error.message}")
      Rails.logger.error(error.backtrace.first(10).join("\n"))
      # TODO: Sentry.capture_exception(error) when error tracking is added
      error!("Something went wrong", code: "INTERNAL_ERROR")

      serialize_with_errors({})
    end
  end
end
