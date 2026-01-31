# frozen_string_literal: true

module Mutations
  class InviteAgent < BaseMutation
    requires_role :admin

    description "Invite a new agent (admin only)"

    argument :email, String, required: true
    argument :is_admin, Boolean, required: false, default_value: false
    argument :name, String, required: true

    field :agent, Types::AgentType, null: true

    def execute(email:, name:, is_admin:)
      agent = Agent.invite!(
        { email: email, name: name, is_admin: is_admin },
        current_user,
      )

      if agent.persisted? && agent.errors.empty?
        { agent: agent }
      else
        agent.errors.each do |err|
          error(err.full_message, field: err.attribute.to_s, code: "VALIDATION_ERROR")
        end
        { agent: nil }
      end
    end
  end
end
