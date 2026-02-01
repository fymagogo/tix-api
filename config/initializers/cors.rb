# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("CUSTOMER_PORTAL_URL", "http://localhost:5173"),
            ENV.fetch("AGENT_PORTAL_URL", "http://localhost:5174")

    resource "*",
             headers: :any,
             methods: [:get, :post, :put, :patch, :delete, :options, :head],
             expose: ["Authorization"],
             credentials: true
  end
end
