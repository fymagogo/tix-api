# frozen_string_literal: true

module Mutations
  class AcceptInvite < BaseMutation
    description "Accept an agent invitation"

    argument :invitation_token, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true

    field :agent, Types::AgentType, null: true
    field :errors, [Types::ErrorType], null: false
    field :token, String, null: true

    def resolve(invitation_token:, password:, password_confirmation:)
      agent = Agent.accept_invitation!(
        invitation_token: invitation_token,
        password: password,
        password_confirmation: password_confirmation,
      )

      if agent.errors.empty?
        token = agent.generate_jwt
        { agent: agent, token: token, errors: [] }
      else
        { agent: nil, token: nil, errors: format_errors(agent) }
      end
    rescue StandardError => e
      { agent: nil, token: nil, errors: [{ field: "base", message: e.message, code: "INVITATION_ERROR" }] }
    end

    private

    def format_errors(record)
      record.errors.map do |error|
        { field: error.attribute.to_s, message: error.message, code: "VALIDATION_ERROR" }
      end
    end
  end
end
