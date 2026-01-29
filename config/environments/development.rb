# frozen_string_literal: true

require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  # Some environments (e.g. Docker bind mounts / network filesystems) don't
  # reliably deliver filesystem events. Allow opting into polling.
  #
  # Usage:
  #   FILE_WATCHER=polling bundle exec rails server
  config.file_watcher = ActiveSupport::FileUpdateChecker if ENV["FILE_WATCHER"].to_s == "polling"

  # Caching
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}",
    }
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  # Active Storage
  config.active_storage.service = :local

  # Action Mailer
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  # Deprecation
  config.active_support.deprecation = :log
  config.active_support.disallowed_deprecation = :raise
  config.active_support.disallowed_deprecation_warnings = []

  # Active Record
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true

  # Default URL options for Active Storage direct uploads
  Rails.application.routes.default_url_options = { host: "localhost", port: 3000 }
end
