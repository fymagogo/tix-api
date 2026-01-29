# frozen_string_literal: true

Devise.setup do |config|
  config.mailer_sender = ENV.fetch("MAILER_FROM", "support@tix.example.com")
  config.mailer = "CustomDeviseMailer"

  require "devise/orm/active_record"

  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth, :params_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = false
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 8..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.responder.error_status = :unprocessable_entity
  config.responder.redirect_status = :see_other

  # JWT Configuration
  config.jwt do |jwt|
    jwt.secret = if Rails.env.production?
                   ENV.fetch("DEVISE_JWT_SECRET_KEY") # Fails loudly if not set in production
                 else
                   ENV.fetch("DEVISE_JWT_SECRET_KEY", "dev-secret-key-not-for-production")
                 end
    jwt.expiration_time = 24.hours.to_i
    jwt.dispatch_requests = [
      ["POST", %r{^/customers/sign_in$}],
      ["POST", %r{^/agents/sign_in$}],
    ]
    jwt.revocation_requests = [
      ["DELETE", %r{^/customers/sign_out$}],
      ["DELETE", %r{^/agents/sign_out$}],
    ]
  end

  # Invitable Configuration
  config.invite_for = 24.hours
  config.invite_key = { email: /\A[^@]+@[^@]+\z/ }
  config.validate_on_invite = true
  config.resend_invitation = true
  config.invited_by_class_name = "Agent"
  config.invited_by_foreign_key = :invited_by_id
end
