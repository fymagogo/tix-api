# Tix API - Rails Backend

This is the Rails 7 API backend for the Tix customer support ticketing system.

## Prerequisites

Before you begin, ensure you have the following installed:

| Dependency | Version | Installation |
|------------|---------|--------------|
| Ruby | 3.3+ | [rbenv](https://github.com/rbenv/rbenv#installation) or [rvm](https://rvm.io/rvm/install) |
| Rails | 7.1+ | `gem install rails` (after Ruby) |
| PostgreSQL | 15+ | [PostgreSQL Downloads](https://www.postgresql.org/download/) or `brew install postgresql@15` |
| Redis | 7+ | [Redis Downloads](https://redis.io/download/) or `brew install redis` |
| Bundler | 2.4+ | `gem install bundler` |

## Quick Start

### With Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# Setup database (create, load schema, seed)
docker-compose exec api bin/rails db:setup

# API is now running at http://localhost:3000
```

### Without Docker

```bash
# Install dependencies
bundle install

# Install git hooks (auto-updates schema, runs RuboCop)
bin/install-hooks

# Setup environment
cp .env.example .env
# Edit .env with your database credentials

# Setup database (create, load schema, seed)
bin/rails db:setup

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
