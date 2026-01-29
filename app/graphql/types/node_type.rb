# frozen_string_literal: true

module Types
  class NodeType < Types::BaseInterface
    include GraphQL::Types::Relay::NodeBehaviors
  end
end
