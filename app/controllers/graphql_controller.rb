# frozen_string_literal: true

class GraphQLController < ApplicationController
  include ActionController::Cookies

  skip_before_action :verify_authenticity_token, raise: false

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]

    context = {
      current_user: current_user_from_cookie,
      current_customer: current_customer_from_cookie,
      current_agent: current_agent_from_cookie,
      request: request,
      response: response,
    }

    result = ::TixApiSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  private

  def decode_jwt(token)
    return nil if token.blank?

    Warden::JWTAuth::TokenDecoder.new.call(token)
  rescue JWT::DecodeError, JWT::ExpiredSignature, JWT::VerificationError
    nil
  end

  def current_user_from_cookie
    current_customer_from_cookie || current_agent_from_cookie
  end

  def current_customer_from_cookie
    @current_customer_from_cookie ||= fetch_customer_from_cookie
  end

  def fetch_customer_from_cookie
    payload = decode_jwt(cookies["customer_access_token"])
    return nil unless payload && payload["sub"] && payload["scp"] == "customer"

    Customer.find_by(id: payload["sub"], jti: payload["jti"])
  end

  def current_agent_from_cookie
    @current_agent_from_cookie ||= fetch_agent_from_cookie
  end

  def fetch_agent_from_cookie
    payload = decode_jwt(cookies["agent_access_token"])
    return nil unless payload && payload["sub"] && payload["scp"] == "agent"

    Agent.find_by(id: payload["sub"], jti: payload["jti"])
  end

  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(error)
    logger.error error.message
    logger.error error.backtrace.join("\n")

    render json: {
      errors: [{ message: error.message, backtrace: error.backtrace.first(10) }],
      data: {},
    }, status: :internal_server_error
  end
end
