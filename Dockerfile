FROM ruby:3.3-slim

# Install dependencies
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev libyaml-dev git curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment 'true' && \
    bundle config set --local without 'development test' && \
    bundle install

# Copy application code
COPY . .

# Precompile bootsnap
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Set environment
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true

# Expose port
EXPOSE 3000

# Start server
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
