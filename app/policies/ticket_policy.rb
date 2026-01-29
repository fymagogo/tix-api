# frozen_string_literal: true

class TicketPolicy < ApplicationPolicy
  def index?
    # Both customers and agents can list tickets (scoped appropriately)
    customer? || agent?
  end

  def show?
    agent? || record.customer == user
  end

  def create?
    customer?
  end

  def update?
    agent?
  end

  def transition?
    agent? && (record.assigned_agent == user || user.is_admin?)
  end

  def assign?
    agent?
  end

  def reassign?
    # Only admin or currently assigned agent can reassign
    agent? && (user.admin? || record.assigned_agent == user)
  end

  def delete?
    # Only admins can delete tickets
    admin?
  end

  def bulk_update?
    admin?
  end

  def export?
    agent?
  end

  def admin?
    user.is_a?(Agent) && user.admin?
  end

  class Scope < Scope
    def resolve
      if user.is_a?(Agent)
        scope.all
      elsif user.is_a?(Customer)
        scope.where(customer: user)
      else
        scope.none
      end
    end
  end
end
