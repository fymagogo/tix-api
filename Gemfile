source "https://rubygems.org"

ruby "4.0.1"

gem "rails", "~> 7.1"
gem "pg", "~> 1.5"
gem "puma", "~> 6.4"
gem "bootsnap", require: false

# Auth
gem "devise", "~> 4.9"
gem "devise-jwt", "~> 0.11"
gem "devise_invitable", "~> 2.0"

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
gem "sidekiq", "~> 7.2"
gem "sidekiq-scheduler", "~> 5.0"
gem "connection_pool", "~> 2.4"  # Pin to 2.x for sidekiq compatibility

# Email
gem "sendgrid-actionmailer", "~> 3.2"

# CORS
gem "rack-cors", "~> 2.0"

# Rate limiting
gem "rack-attack", "~> 6.7"

# JSON
gem "jbuilder", "~> 2.11"

# CSV (required in Ruby 3.4+)
gem "csv", "~> 3.3"

group :development, :test do
  gem "debug", platforms: %i[mri windows]
  gem "rspec-rails", "~> 6.1"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.2"
  gem "pry-rails", "~> 0.3"
end

group :development do
  gem "letter_opener", "~> 1.8"
  gem "graphiql-rails", "~> 1.9"
  gem "listen", "~> 3.9"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "database_cleaner-active_record", "~> 2.1"
  gem "simplecov", "~> 0.22", require: false
end
