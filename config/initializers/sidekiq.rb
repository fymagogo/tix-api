# frozen_string_literal: true

require "sidekiq-scheduler"

Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Load and enable scheduler (only in server context)
  config.on(:startup) do
    schedule_file = Rails.root.join("config", "sidekiq_schedule.yml")
    if File.exist?(schedule_file)
      Sidekiq.schedule = YAML.load_file(schedule_file)
      SidekiqScheduler::Scheduler.instance.reload_schedule!
      Rails.logger.info "Sidekiq scheduler loaded with #{Sidekiq.schedule.keys.count} jobs"
    end
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
