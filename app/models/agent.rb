# frozen_string_literal: true

class Agent < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include AuditableHistory

  devise :invitable, :database_authenticatable, :recoverable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  audited

  has_many :assigned_tickets, class_name: "Ticket", foreign_key: "assigned_agent_id", dependent: :nullify
  has_many :comments, as: :author, dependent: :destroy
  has_many :invitees, class_name: "Agent", foreign_key: "invited_by_id", dependent: :nullify
  belongs_to :invited_by, class_name: "Agent", optional: true

  validates :name, presence: true, unless: :invitation_token?
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  scope :active, -> { where(invitation_accepted_at: ..Time.current).or(where(invitation_token: nil)) }

  # Convenience method for checking admin status
  def admin?
    is_admin
  end

  # Round-robin assignment: get non-admin agent with oldest last_assigned_at
  # Agents who have never been assigned (NULL) should be picked first
  def self.next_for_assignment
    active.where(is_admin: false).order(Arel.sql("last_assigned_at ASC NULLS FIRST")).first
  end

  # Generate a JWT token for this agent (used by GraphQL sign-in)
  def generate_jwt
    Warden::JWTAuth::UserEncoder.new.call(self, :agent, nil).first
  end
end
