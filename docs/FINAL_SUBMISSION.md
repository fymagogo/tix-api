# Tix - Final Submission

## Project Overview

**Tix** is a full-stack customer support ticketing system featuring a Rails GraphQL API backend and a Vue 3 monorepo frontend with two separate portals for customers and support agents.

---

## 1. GitHub Repositories

### Backend (Rails API)
**Repository:** https://github.com/fymagogo/tix-api

Contains:
| Requirement | Location |
|-------------|----------|
| **a. README with setup instructions** | [`README.md`](https://github.com/fymagogo/tix-api/blob/main/README.md) - Includes Docker and non-Docker setup, test accounts, and API endpoint info |
| **b. Schema and migration files** | [`db/schema.rb`](https://github.com/fymagogo/tix-api/blob/main/db/schema.rb) and [`db/migrate/`](https://github.com/fymagogo/tix-api/tree/main/db/migrate) - 12 migration files |
| **c. GraphQL schema definition** | [`schema.graphql`](https://github.com/fymagogo/tix-api/blob/main/schema.graphql) (671 lines SDL) and [`app/graphql/`](https://github.com/fymagogo/tix-api/tree/main/app/graphql) (code-first types, mutations, resolvers) |
| **d. Unit and integration tests** | [`spec/`](https://github.com/fymagogo/tix-api/tree/main/spec) - 55 test files covering models, policies, GraphQL, mailers, jobs, and integration tests |

### Frontend (Vue 3 Monorepo)
**Repository:** https://github.com/fymagogo/tix-frontend

Contains:
- Customer Portal (`apps/customer-portal/`)
- Agent Portal (`apps/agent-portal/`)
- Shared UI components (`packages/ui/`)
- GraphQL client and types (`packages/graphql/`)

---

## 2. Deployed Application Links

| Application | URL |
|-------------|-----|
| **Customer Portal** | https://tix-frontend-customer-portal.vercel.app |
| **Agent Portal** | https://tix-frontend-agent-portal-lgkn.vercel.app |
| **API (GraphQL)** | https://extraordinary-learning-production.up.railway.app/graphql |

### Test Accounts

| Type | Email | Password |
|------|-------|----------|
| Admin Agent | admin@tix.test | password123 |
| Regular Agent | agent1@tix.test | password123 |
| Customer | customer1@example.com | password123 |

### Deployment Stack

| Service | Platform |
|---------|----------|
| Frontend (both portals) | Vercel (static sites with SPA routing) |
| API | Railway (Docker container) |
| Sidekiq (background jobs) | Railway (separate service) |
| PostgreSQL | Railway (managed) |
| Redis | Railway (managed) |

---

## 3. Key Decisions and Reasons

### Architecture Decisions

| Decision | Reasoning |
|----------|-----------|
| **Separate Customer/Agent models** | Instead of a single User model with roles, I used separate `Customer` and `Agent` models. This provides cleaner separation of concerns, different authentication flows, and avoids complex polymorphic relationships for tickets. |
| **GraphQL over REST** | GraphQL enables the frontend to request exactly the data it needs, reduces over-fetching, and provides strong typing. The single endpoint also simplifies CORS configuration. |
| **Code-first GraphQL schema** | Using `graphql-ruby` with Ruby class definitions (rather than SDL-first) keeps type definitions close to resolvers and enables better IDE support and runtime type checking. |
| **Cookie-based JWT with refresh tokens** | Access tokens expire in 15 minutes, refresh tokens in 7 days. This balances security (short-lived access) with UX (seamless session refresh). HttpOnly cookies prevent XSS token theft. |
| **AASM for ticket state machine** | The `aasm` gem provides explicit state transitions with validations, preventing invalid status changes and enabling transition callbacks for notifications. |
| **Monorepo with pnpm workspaces** | Shared UI components and GraphQL client reduce duplication between portals while keeping apps independently deployable. |
| **Round-robin ticket assignment** | Fair distribution among agents by assigning to the agent with fewest active tickets, excluding admins who focus on management tasks. |

### Technical Decisions

| Decision | Reasoning |
|----------|-----------|
| **Pundit for authorization** | Policy objects keep authorization logic organized and testable. Each resource has clear, explicit access rules. |
| **Sidekiq for background jobs** | Production-ready job processing for email notifications, daily reminders, and CSV exports. The scheduler handles recurring jobs like the 9am reminder. |
| **ActiveStorage with S3** | File attachments (ticket images, comment attachments) use Rails' built-in ActiveStorage, configured for S3 in production for durability and CDN-friendly serving. |
| **SameSite=None cookies in production** | Required for cross-domain cookie authentication between Vercel (frontend) and Railway (API) - different domains need SameSite=None + Secure. |
| **Audited gem for history** | Automatic change tracking on tickets provides a complete audit trail without manual logging code. Customers and agents can see the full ticket history. |

---

## 4. Issues Faced During Implementation

### Deployment Challenges

| Issue | Solution |
|-------|----------|
| **vue-tsc incompatibility with TypeScript 5.9** | Updated vue-tsc to v2.x which properly supports TS 5.9 |
| **TypeScript project references conflict** | Removed composite references from app tsconfigs; workspaces don't need them with pnpm |
| **Railway internal hostnames not accessible locally** | Can't use `railway run` for migrations since `*.railway.internal` only resolves inside Railway's network. Used Railway Dashboard shell instead. |
| **CORS errors on cross-domain requests** | Added Vercel frontend URLs to Railway environment variables for CORS allowlist |
| **Cookies not persisting after login** | Changed `SameSite=Lax` to `SameSite=None` for production cross-domain cookies |
| **ActionDispatch::Static middleware error** | Rails API-only mode doesn't load Static middleware; changed security headers to insert after `Rack::Sendfile` instead |
| **ActiveStorage S3 initialization failure** | Made S3 storage conditional - only use Amazon storage if `AWS_S3_BUCKET` env var is set, otherwise fall back to local disk |

### Development Challenges

| Issue | Solution |
|-------|----------|
| **Polymorphic user in GraphQL** | Created a `UserType` union type that resolves to either `AgentType` or `CustomerType` based on the object type |
| **Ticket number generation** | Used PostgreSQL sequence with formatted prefix (`TIX-000001`) for human-readable, sequential ticket IDs |
| **Refresh token security** | Store only hashed tokens in database; the raw token is returned once to client and stored in HttpOnly cookie |

---

## 5. What I Would Do Differently With More Time

### Features I Would Add

1. **SLA Management** - Define response/resolution time targets per customer tier, visual countdown timers, breach alerts, and compliance reporting. This is critical for enterprise support operations.

2. **Ticket Categories** - Allow categorization (Billing, Technical, Feature Request) for better organization, routing rules, and analytics.

3. **Real-time Updates via WebSockets** - Replace 10-second polling with GraphQL subscriptions using ActionCable. This would provide instant comment updates and status changes.

4. **Customer Satisfaction Surveys** - Send survey link when tickets close, track CSAT scores per agent, and display metrics on admin dashboard.

5. **Knowledge Base Integration** - Suggest relevant help articles when customers create tickets, potentially deflecting simple issues.

### Technical Improvements

1. **Better test coverage** - Add end-to-end tests with Playwright/Cypress for critical user flows (login, create ticket, resolve ticket).

2. **API rate limiting refinement** - The current rack-attack setup is basic; would add per-user limits and more granular throttling.

3. **Error monitoring** - Integrate Sentry for production error tracking and alerting.

4. **Performance optimization** - Add database indexes based on query patterns, implement Redis caching for frequently-accessed data.

5. **CI/CD improvements** - Add staging environment, automated deployment gates, and database migration safety checks.

### Architecture Improvements

1. **Microservices consideration** - For scale, extract email/notification service and export service as separate workers.

2. **Multi-tenancy** - Support multiple organizations with data isolation for a SaaS offering.

3. **API versioning** - Implement GraphQL schema versioning strategy for backward compatibility.

---

## Documentation

Additional documentation is available in the repository:

| Document | Description |
|----------|-------------|
| [`docs/API.md`](https://github.com/fymagogo/tix-api/blob/main/docs/API.md) | Full GraphQL API documentation with queries, mutations, and types |
| [`docs/DEPLOYMENT.md`](https://github.com/fymagogo/tix-api/blob/main/docs/DEPLOYMENT.md) | Infrastructure and deployment guide |
| [`docs/ADMIN_FUNCTIONS.md`](https://github.com/fymagogo/tix-api/blob/main/docs/ADMIN_FUNCTIONS.md) | Admin-only features and permissions |
| [`docs/FRONTEND.md`](https://github.com/fymagogo/tix-api/blob/main/docs/FRONTEND.md) | Frontend architecture and component documentation |
| [`docs/FUTURE_CONSIDERATIONS.md`](https://github.com/fymagogo/tix-api/blob/main/docs/FUTURE_CONSIDERATIONS.md) | Detailed plans for future enhancements |

---

## Summary

Tix demonstrates a production-ready customer support system with:

- **Clean architecture** - Separation of concerns with policies, services, and typed GraphQL
- **Security** - JWT authentication, CSRF protection, rate limiting, and audit logging
- **Scalability** - Background job processing, database optimization, and cloud-native deployment
- **Developer experience** - Comprehensive documentation, automated testing, and CI/CD pipeline
- **User experience** - Responsive design, real-time-ish updates, and intuitive workflows

Thank you for reviewing this submission!
