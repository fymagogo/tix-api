# frozen_string_literal: true

class TixApiSchema < GraphQL::Schema
  mutation(Types::MutationType)
  query(Types::QueryType)

  # Enable Dataloader for batching
  use GraphQL::Dataloader

  # Error handling
  rescue_from(ActiveRecord::RecordNotFound) do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(
      "Record not found",
      extensions: { code: "NOT_FOUND" }
    )
  end

  rescue_from(Pundit::NotAuthorizedError) do |_err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(
      "Not authorized",
      extensions: { code: "UNAUTHORIZED" }
    )
  end

  rescue_from(AASM::InvalidTransition) do |err, _obj, _args, _ctx, _field|
    raise GraphQL::ExecutionError.new(
      "Invalid status transition: #{err.message}",
      extensions: { code: "INVALID_TRANSITION" }
    )
  end

  # Union/Interface resolution
  def self.resolve_type(abstract_type, object, _context)
    case object
    when Customer
      Types::CustomerType
    when Agent
      Types::AgentType
    when Ticket
      Types::TicketType
    when Comment
      Types::CommentType
    else
      raise GraphQL::RequiredImplementationMissingError, "Unknown type: #{object.class}"
    end
  end

  # Limit query complexity
  max_complexity 200
  max_depth 15

  # Timeout for queries (10 seconds)
  default_max_page_size 50

  # Disable introspection in production for security
  disable_introspection_entry_points if Rails.env.production?

  # Orphan types
  orphan_types Types::CustomerType, Types::AgentType
end
