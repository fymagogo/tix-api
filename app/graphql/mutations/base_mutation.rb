# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::Mutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    object_class Types::BaseObject

    # Shared authorization helpers
    def authorize!(record, action)
      policy = Pundit.policy!(current_user, record)
      raise GraphQL::ExecutionError, "Not authorized" unless policy.public_send(action)
    end

    def current_user
      context[:current_user]
    end

    def authenticate!
      raise GraphQL::ExecutionError, "Authentication required" unless current_user
    end

    def require_agent!
      authenticate!
      raise GraphQL::ExecutionError, "Agent access required" unless current_user.is_a?(Agent)
    end

    def require_admin!
      require_agent!
      raise GraphQL::ExecutionError, "Admin access required" unless current_user.is_admin
    end

    def require_customer!
      authenticate!
      raise GraphQL::ExecutionError, "Customer access required" unless current_user.is_a?(Customer)
    end
  end
end
