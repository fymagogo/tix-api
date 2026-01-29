# Tix API - Rails Backend

This is the Rails 7 API backend for the Tix customer support ticketing system.

## Prerequisites

- Ruby 3.2.2
- PostgreSQL 15+
- Redis 7+

## Quick Start

### With Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# Create and seed database
docker-compose exec api bin/rails db:create db:migrate db:seed

# API is now running at http://localhost:3000
```

### Without Docker

```bash
# Install dependencies
bundle install

# Setup environment
cp .env.example .env
# Edit .env with your database credentials

# Setup database
bin/rails db:create db:migrate db:seed

# Start server
bin/rails server
```

## Test Accounts

After seeding:

| Type | Email | Password |
|------|-------|----------|
| Admin | admin@tix.test | password123 |
| Agent | agent1@tix.test | password123 |
| Customer | customer1@example.com | password123 |

## GraphQL Playground

Visit http://localhost:3000/graphiql in development mode.

## Running Tests

```bash
bundle exec rspec
```

## API Endpoint

All GraphQL queries go to: `POST /graphql`

See [docs/API.md](../docs/API.md) for full documentation.
