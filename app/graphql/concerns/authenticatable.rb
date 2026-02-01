# frozen_string_literal: true

module Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def requires_auth(required = true)
      @requires_auth = required
    end

    def requires_auth?
      @requires_auth.nil? || @requires_auth
    end

    def requires_role(*roles)
      @required_roles = roles
    end

    def required_roles
      @required_roles || []
    end
  end

  def current_user
    context[:current_user]
  end

  def current_agent
    current_user if current_user.is_a?(Agent)
  end

  def current_customer
    current_user if current_user.is_a?(Customer)
  end

  def signed_in?
    current_user.present?
  end

  # Called before resolve - checks authentication and role requirements
  # Returns true if authorized, otherwise raises GraphQL::ExecutionError
  def check_auth!
    if self.class.requires_auth? && !signed_in?
      raise GraphQL::ExecutionError.new(
        "Authentication required",
        extensions: { code: "UNAUTHENTICATED" },
      )
    end

    check_required_roles!
  end

  private

  def check_required_roles!
    roles = self.class.required_roles
    return true if roles.empty?

    # Check agent role (including when admin is required, since admin must be an agent)
    if (roles.include?(:agent) || roles.include?(:admin)) && !current_user.is_a?(Agent)
      raise GraphQL::ExecutionError.new(
        "Agent access required",
        extensions: { code: "UNAUTHORIZED" },
      )
    end

    # Check admin role (must be an agent first, checked above)
    if roles.include?(:admin) && !current_user.is_admin
      raise GraphQL::ExecutionError.new(
        "Admin access required",
        extensions: { code: "UNAUTHORIZED" },
      )
    end

    if roles.include?(:customer) && !current_user.is_a?(Customer)
      raise GraphQL::ExecutionError.new(
        "Customer access required",
        extensions: { code: "UNAUTHORIZED" },
      )
    end

    true
  end
end
