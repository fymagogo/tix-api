# frozen_string_literal: true

class Customer < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  include AuditableHistory

  devise :database_authenticatable, :registerable, :recoverable,
         :validatable, :jwt_authenticatable, jwt_revocation_strategy: self

  audited

  has_many :tickets, dependent: :destroy
  has_many :comments, as: :author, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # Generate a JWT token for this customer (used by GraphQL sign-in/sign-up)
  def generate_jwt
    Warden::JWTAuth::UserEncoder.new.call(self, :customer, nil).first
  end
end
