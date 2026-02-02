# frozen_string_literal: true

require "sidekiq-scheduler"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Load schedule from YAML file (only in server context)
  config.on(:startup) do
    Sidekiq.schedule = YAML.load_file(Rails.root.join("config", "sidekiq_schedule.yml"))
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
