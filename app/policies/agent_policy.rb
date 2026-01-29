# frozen_string_literal: true

class AgentPolicy < ApplicationPolicy
  def index?
    agent?
  end

  def show?
    agent?
  end

  def invite?
    agent?
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
