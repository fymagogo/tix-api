require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module TixApi
  class Application < Rails::Application
    config.load_defaults 7.1

    # API-only mode
    config.api_only = true

    # But we need session for GraphiQL in development
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore

    # Autoload/eager-load custom directories (Zeitwerk).
    config.autoload_paths << Rails.root.join("app/graphql")
    config.autoload_paths << Rails.root.join("app/services")
    config.autoload_paths << Rails.root.join("app/models/concerns")
    config.eager_load_paths << Rails.root.join("app/graphql")
    config.eager_load_paths << Rails.root.join("app/services")
    config.eager_load_paths << Rails.root.join("app/models/concerns")

    # Active Job
    config.active_job.queue_adapter = :sidekiq

    # Generators
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end
  end
end
