require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false

  # Caching
  config.cache_store = :memory_store
  config.public_file_server.enabled = ENV["RAILS_SERVE_STATIC_FILES"].present?

  # Active Storage
  config.active_storage.service = :amazon

  # Force SSL
  config.force_ssl = true
  config.assume_ssl = true

  # Logging
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }
  config.log_tags = [:request_id]
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Action Mailer
  config.action_mailer.perform_caching = false
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :sendgrid_actionmailer
  config.action_mailer.sendgrid_actionmailer_settings = {
    api_key: ENV["SENDGRID_API_KEY"],
    raise_delivery_errors: true
  }
  config.action_mailer.default_url_options = { host: ENV["APP_HOST"], protocol: "https" }

  # Routes default URL options (for ActiveStorage URLs)
  Rails.application.routes.default_url_options = { host: ENV["APP_HOST"], protocol: "https" }

  # i18n
  config.i18n.fallbacks = true

  # Deprecation
  config.active_support.deprecation = :notify
  config.active_support.report_deprecations = false

  # Active Record
  config.active_record.dump_schema_after_migration = false
end
