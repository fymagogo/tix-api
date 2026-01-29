# frozen_string_literal: true

# Configure Devise to use ActiveJob for async emails
Rails.application.config.to_prepare do
  Devise::Mailer.delivery_system = :sendgrid if Rails.env.production?
end
