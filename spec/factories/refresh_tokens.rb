# frozen_string_literal: true

FactoryBot.define do
  factory :refresh_token do
    association :user, factory: :customer
    token_digest { Digest::SHA256.hexdigest(SecureRandom.urlsafe_base64(32)) }
    expires_at { 7.days.from_now }
    revoked_at { nil }
  end
end
