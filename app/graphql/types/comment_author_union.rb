# frozen_string_literal: true

module Types
  class CommentAuthorUnion < Types::BaseUnion
    description "The author of a comment (Customer or Agent)"
    possible_types Types::CustomerType, Types::AgentType

    def self.resolve_type(object, _context)
      case object
      when Customer
        Types::CustomerType
      when Agent
        Types::AgentType
      else
        raise GraphQL::RequiredImplementationMissingError, "Unknown author type: #{object.class}"
      end
    end
  end
end
