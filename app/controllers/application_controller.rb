# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pundit::Authorization

  before_action :set_current_user

  rescue_from Pundit::NotAuthorizedError, with: :render_unauthorized

  protected

  def current_user
    current_customer || current_agent
  end

  def authenticate_user!
    return if current_user

    render json: { error: "Not authenticated" }, status: :unauthorized
  end

  private

  def set_current_user
    Current.user = current_user
    Audited.store[:audited_user] = current_user
  end

  def render_unauthorized
    render json: { error: "Not authorized" }, status: :forbidden
  end
end
