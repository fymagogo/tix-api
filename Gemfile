# frozen_string_literal: true

source "https://rubygems.org"

ruby "4.0.1"

gem "bootsnap", require: false
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "rails", "~> 7.1"

# Auth
gem "devise", "~> 4.9"
gem "devise_invitable", "~> 2.0"
gem "devise-jwt", "~> 0.11"

# Authorization
gem "pundit", "~> 2.3"

# GraphQL
gem "graphql", "~> 2.2"

# State machine
gem "aasm", "~> 5.5"

# Audit logging
gem "audited", "~> 5.4"

# Pagination
gem "kaminari", "~> 1.2"

# Background jobs
gem "connection_pool", "~> 2.4" # Pin to 2.x for sidekiq compatibility
gem "sidekiq", "~> 7.2"
gem "sidekiq-scheduler", "~> 5.0"

# Email
gem "sendgrid-actionmailer", "~> 3.2"

# CORS
gem "rack-cors", "~> 2.0"

# Rate limiting
gem "rack-attack", "~> 6.7"

# Structured logging
gem "lograge", "~> 0.14"

# JSON
gem "jbuilder", "~> 2.11"

# CSV (required in Ruby 3.4+)
gem "csv", "~> 3.3"

group :development, :test do
  gem "debug", platforms: [:mri, :windows]
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "pry-rails", "~> 0.3"
  gem "rspec-rails", "~> 6.1"
  gem "rubocop", "~> 1.60", require: false
  gem "rubocop-graphql", "~> 1.5", require: false
  gem "rubocop-rails", "~> 2.23", require: false
  gem "rubocop-rspec", "~> 2.26", require: false
end

group :development do
  gem "graphiql-rails", "~> 1.9"
  gem "letter_opener", "~> 1.8"
  gem "listen", "~> 3.9"
end

group :test do
  gem "database_cleaner-active_record", "~> 2.1"
  gem "shoulda-matchers", "~> 6.0"
  gem "simplecov", "~> 0.22", require: false
end
