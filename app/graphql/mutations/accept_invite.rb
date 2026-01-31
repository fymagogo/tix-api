# frozen_string_literal: true

module Mutations
  class AcceptInvite < BaseMutation
    include CookieAuth

    requires_auth false

    description "Accept an agent invitation"

    argument :invitation_token, String, required: true
    argument :password, String, required: true
    argument :password_confirmation, String, required: true

    field :agent, Types::AgentType, null: true

    def execute(invitation_token:, password:, password_confirmation:)
      agent = Agent.accept_invitation!(
        invitation_token: invitation_token,
        password: password,
        password_confirmation: password_confirmation,
      )

      if agent.errors.empty?
        set_auth_cookies(agent, context[:response])
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
