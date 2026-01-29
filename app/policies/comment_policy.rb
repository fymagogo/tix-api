# frozen_string_literal: true

class CommentPolicy < ApplicationPolicy
  def create?
    return true if agent?
    return false unless customer?

    # Customer can only comment if an agent has commented first
    record.ticket.comments.exists?(author_type: "Agent")
  end

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
