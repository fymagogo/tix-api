# frozen_string_literal: true

# Security headers middleware for production
class SecurityHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, response = @app.call(env)

    # Prevent clickjacking
    headers["X-Frame-Options"] = "DENY"

    # XSS protection
    headers["X-XSS-Protection"] = "1; mode=block"

    # Prevent MIME type sniffing
    headers["X-Content-Type-Options"] = "nosniff"

    # Referrer policy
    headers["Referrer-Policy"] = "strict-origin-when-cross-origin"

    # Content Security Policy for API responses
    headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"

    # Permissions policy
    headers["Permissions-Policy"] =
      "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()"

    [status, headers, response]
  end
end

# Only add in production
Rails.application.config.middleware.insert_after ActionDispatch::Static, SecurityHeaders if Rails.env.production?
