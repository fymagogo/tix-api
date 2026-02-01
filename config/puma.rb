# frozen_string_literal: true

# Puma configuration file for production deployment
# https://puma.io/puma/Puma/DSL.html

# Thread pool configuration
# Each worker uses threads to handle concurrent requests
max_threads_count = ENV.fetch("RAILS_MAX_THREADS", 5)
min_threads_count = ENV.fetch("RAILS_MIN_THREADS", max_threads_count)
threads min_threads_count, max_threads_count

# Port to listen on (Render provides $PORT automatically)
port ENV.fetch("PORT", 3000)

# Match Puma environment to Rails environment
environment ENV.fetch("RAILS_ENV", "development")

# Store process ID for process management
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Worker processes - each is a separate OS process
# Adjust based on available memory:
#   512MB (free tier): 1 worker
#   1GB: 2 workers
#   2GB: 4 workers
workers ENV.fetch("WEB_CONCURRENCY", 2)

# Preload app before forking workers
# Reduces memory usage via copy-on-write
# Speeds up worker boot time
preload_app!

# Allow puma to be restarted by `touch tmp/restart.txt`
plugin :tmp_restart

# Ensure proper database connection handling after fork
on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end

# Embedded Sidekiq for free tier hosting (no separate worker process)
# Runs Sidekiq in a background thread within the web process
if ENV["SIDEKIQ_EMBEDDED"] == "true"
  require "sidekiq"

  on_worker_boot do
    @sidekiq_capsule = Sidekiq.configure_embed do |config|
      config.queues = ["ticket_assignment", "mailers", "exports", "default"]
      config.concurrency = 2 # Keep low to share resources with web
    end
    @sidekiq_capsule.run
  end

  on_worker_shutdown do
    @sidekiq_capsule&.stop
  end
end
