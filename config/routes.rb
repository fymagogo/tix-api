Rails.application.routes.draw do
  require "sidekiq/web"
  require "sidekiq-scheduler/web"

  # Devise routes for Customer
  devise_for :customers,
    path: "customers",
    controllers: {
      sessions: "customers/sessions",
      registrations: "customers/registrations",
      passwords: "customers/passwords"
    }

  # Devise routes for Agent
  devise_for :agents,
    path: "agents",
    controllers: {
      sessions: "agents/sessions",
      passwords: "agents/passwords",
      invitations: "agents/invitations"
    }

  # GraphQL endpoint
  post "/graphql", to: "graphql#execute"

  # GraphiQL in development
  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  # Sidekiq Web UI
  #
  # Enabled by default in development/test.
  # In other environments, set ENABLE_SIDEKIQ_UI=true and provide:
  #   SIDEKIQ_UI_USERNAME, SIDEKIQ_UI_PASSWORD
  if Rails.env.development? || Rails.env.test? || ENV["ENABLE_SIDEKIQ_UI"].to_s == "true"
    if Rails.env.production? || Rails.env.staging?
      username = ENV.fetch("SIDEKIQ_UI_USERNAME", nil)
      password = ENV.fetch("SIDEKIQ_UI_PASSWORD", nil)

      if username.blank? || password.blank?
        raise "Sidekiq UI enabled but SIDEKIQ_UI_USERNAME/PASSWORD not set"
      end

      Sidekiq::Web.use Rack::Auth::Basic do |provided_username, provided_password|
        ActiveSupport::SecurityUtils.secure_compare(provided_username.to_s, username) &
          ActiveSupport::SecurityUtils.secure_compare(provided_password.to_s, password)
      end
    end

    mount Sidekiq::Web, at: "/sidekiq"
  end

  # Health check
  get "/health", to: proc { [200, {}, ["OK"]] }
end
