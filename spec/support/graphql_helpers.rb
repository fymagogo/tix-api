# frozen_string_literal: true

module GraphqlHelpers
  class MockResponse
    attr_reader :cookies

    def initialize
      @cookies = {}
    end

    def set_cookie(name, options)
      @cookies[name.to_s] = options
    end

    def delete_cookie(name, _options = {})
      @cookies.delete(name.to_s)
    end
  end

  class MockRequest
    attr_reader :cookies

    def initialize(cookies = {})
      @cookies = cookies.stringify_keys
    end
  end

  def execute_graphql(query:, variables: {}, context: {}, cookies: {})
    @mock_response = MockResponse.new
    @mock_request = MockRequest.new(cookies)

    default_context = {
      response: @mock_response,
      request: @mock_request,
    }

    result = TixApiSchema.execute(
      query,
      variables: variables.deep_stringify_keys,
      context: default_context.merge(context),
      operation_name: nil,
    )
    @graphql_response = result.to_h
    result.to_h
  end

  def response_cookies
    @mock_response&.cookies || {}
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
