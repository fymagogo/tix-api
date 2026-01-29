# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :me, Types::CommentAuthorUnion, null: true, description: "Currently authenticated user"

    field :ticket, Types::TicketType, null: true, description: "Find a ticket by ID" do
      argument :id, ID, required: true
    end

    field :ticket_by_number, Types::TicketType, null: true, description: "Find a ticket by ticket number" do
      argument :ticket_number, String, required: true
    end

    field :tickets, resolver: Resolvers::TicketsResolver

    field :agents, [Types::AgentType], null: false, description: "List all agents (agents only)"

    field :agent, Types::AgentType, null: true, description: "Find an agent by ID (agents only)" do
      argument :id, ID, required: true
    end

    def me
      context[:current_user]
    end

    def ticket(id:)
      ticket = Ticket.find(id)
      authorize_record(ticket, :show?)
      ticket
    end

    def ticket_by_number(ticket_number:)
      user = context[:current_user]
      return nil unless user

      normalized = ticket_number.to_s.upcase
      ticket = Ticket.find_by(ticket_number: normalized)
      return nil unless ticket

      policy = Pundit.policy!(user, ticket)
      return nil unless policy.show?

      ticket
    end

    def agents
      authorize_record(Agent, :index?)
      Agent.active.order(:name)
    end

    def agent(id:)
      agent = Agent.find(id)
      authorize_record(agent, :show?)
      agent
    end

    private

    def authorize_record(record, action)
      policy = Pundit.policy!(context[:current_user], record)
      raise Pundit::NotAuthorizedError unless policy.public_send(action)
    end
  end
end
