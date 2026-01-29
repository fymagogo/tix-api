# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new

  # Include additional request details
  config.lograge.custom_options = lambda do |event|
    {
      request_id: event.payload[:request_id],
      user_type: event.payload[:user_type],
      user_id: event.payload[:user_id],
      ip: event.payload[:ip],
      host: event.payload[:host],
      time: Time.current.iso8601,
    }.compact
  end

  # Suppress ActionController default logging
  config.lograge.ignore_actions = []

  # Include exception details if present
  config.lograge.custom_payload do |controller|
    {
      request_id: controller.request.request_id,
      user_type: controller.try(:current_user)&.class&.name,
      user_id: controller.try(:current_user)&.id,
      ip: controller.request.remote_ip,
      host: controller.request.host,
    }
  end
end
