# frozen_string_literal: true

class AgentPolicy < ApplicationPolicy
  def index?
    agent?
  end

  def show?
    agent?
  end

  def invite?
    admin?
  end

  def deactivate?
    admin?
  end

  def update_role?
    admin?
  end

  def admin?
    user.is_a?(Agent) && user.admin?
  end

  class Scope < Scope
    def resolve
      if user.is_a?(Agent)
        scope.all
      else
        scope.none
      end
    end
  end
end
