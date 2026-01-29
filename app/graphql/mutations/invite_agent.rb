# frozen_string_literal: true

module Mutations
  class InviteAgent < BaseMutation
    description "Invite a new agent (admin only)"

    argument :email, String, required: true
    argument :is_admin, Boolean, required: false, default_value: false
    argument :name, String, required: true

    field :agent, Types::AgentType, null: true
    field :errors, [Types::ErrorType], null: false

    def resolve(email:, name:, is_admin:)
      require_admin!

      agent = Agent.invite!(
        { email: email, name: name, is_admin: is_admin },
        current_user,
      )

      if agent.persisted? && agent.errors.empty?
        { agent: agent, errors: [] }
      else
        { agent: nil, errors: format_errors(agent) }
      end
    rescue StandardError => e
      { agent: nil, errors: [{ field: "base", message: e.message, code: "INVITE_ERROR" }] }
    end

    private

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.message, code: "VALIDATION_ERROR" }
      end
    end
  end
end
