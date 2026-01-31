# frozen_string_literal: true

class RefreshToken < ApplicationRecord
  EXPIRY_DURATION = 7.days
  TOKEN_LENGTH = 32

  belongs_to :user, polymorphic: true

  validates :token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where(revoked_at: nil).where("expires_at > ?", Time.current) }
  scope :expired_or_revoked, -> { where("revoked_at IS NOT NULL OR expires_at <= ?", Time.current) }

  class << self
    # Generate a new refresh token for a user
    # Returns [token_record, raw_token] - raw_token is what gets stored in the cookie
    def generate_for(user)
      raw_token = SecureRandom.urlsafe_base64(TOKEN_LENGTH)
      token_digest = digest(raw_token)

      record = create!(
        user: user,
        token_digest: token_digest,
        expires_at: EXPIRY_DURATION.from_now,
      )

      [record, raw_token]
    end

    # Find a valid refresh token by raw token value
    def find_by_token(raw_token)
      return nil if raw_token.blank?

      active.find_by(token_digest: digest(raw_token))
    end

    # Securely hash the token for storage
    def digest(token)
      Digest::SHA256.hexdigest(token)
    end

    # Clean up old tokens (run periodically via job)
    def cleanup_expired!
      expired_or_revoked.where("created_at < ?", 30.days.ago).delete_all
    end
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def valid_token?
    !revoked? && !expired?
  end

  # Rotate the token - revoke current and create new one
  def rotate!
    revoke!
    self.class.generate_for(user)
  end
end
