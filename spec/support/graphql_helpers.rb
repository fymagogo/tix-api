# frozen_string_literal: true

module GraphqlHelpers
  def execute_graphql(query:, variables: {}, context: {})
    result = TixApiSchema.execute(
      query,
      variables: variables.deep_stringify_keys,
      context: context,
      operation_name: nil
    )
    @graphql_response = result.to_h
    result.to_h
  end

  def graphql_response
    @graphql_response ||= {}
  end

  def graphql_data
    graphql_response["data"]
  end

  def graphql_errors
    graphql_response["errors"]
  end
end

RSpec.configure do |config|
  config.include GraphqlHelpers, type: :graphql
end
