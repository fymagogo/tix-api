# frozen_string_literal: true

module Types
  class TicketType < Types::BaseObject
    description "A support ticket"

    field :id, ID, null: false
    field :ticket_number, String, null: false
    field :subject, String, null: false
    field :description, String, null: false
    field :status, String, null: false
    field :customer, Types::CustomerType, null: false
    field :assigned_agent, Types::AgentType, null: true
    field :comments, [Types::CommentType], null: false, complexity: 10
    field :status_history, [Types::StatusChangeType], null: false, complexity: 5
    field :history, [Types::HistoryEventType], null: false, description: "Human-readable history events", complexity: 15
    field :can_comment, Boolean, null: false, description: "Whether the current user can add a comment"
    field :attachments, [Types::AttachmentType], null: false, description: "File attachments", complexity: 5
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :closed_at, GraphQL::Types::ISO8601DateTime, null: true

    def comments
      object.comments.ordered
    end

    def status_history
      object.status_changes
    end

    def history
      object.human_readable_history
    end

    def can_comment
      return false if object.closed?

      current_user = context[:current_user]
      return false unless current_user

      # Agents can always comment on non-closed tickets
      return true if current_user.is_a?(Agent)

      # Customers can only comment after an agent has responded
      object.comments.exists?(author_type: "Agent")
    end
  end
end
