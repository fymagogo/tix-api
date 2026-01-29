# frozen_string_literal: true

module AuthHelpers
  def auth_headers_for(user)
    token = generate_jwt_token(user)
    { "Authorization" => "Bearer #{token}" }
  end

  def generate_jwt_token(user)
    payload = {
      jti: user.jti,
      sub: user.id,
      scope: user.class.name.underscore,
      iat: Time.current.to_i,
      exp: 24.hours.from_now.to_i,
    }

    secret = Rails.application.credentials.devise_jwt_secret_key ||
             Rails.application.credentials.secret_key_base ||
             "test-secret-key-for-rspec"

    JWT.encode(payload, secret, "HS256")
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
