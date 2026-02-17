# CLAUDE.md

This file provides guidance for AI assistants working with this codebase.

## Project Overview

Rails 8.1 API-only application (module name: `Workspace`) providing JWT-authenticated RESTful endpoints with role-based access control (RBAC). Built with Ruby 3.2.8, PostgreSQL 15, and Devise+JWT for authentication.

## Common Commands

### Development
```bash
bin/rails server                  # Start development server
bin/rails console                 # Interactive Rails console
bin/rails routes                  # List all routes
```

### Database
```bash
bin/rails db:create               # Create databases
bin/rails db:migrate              # Run pending migrations
bin/rails db:seed                 # Seed database
bin/rails db:test:prepare         # Prepare test database
```

### Testing
```bash
bin/rails test                    # Run full test suite
bin/rails test test/models/       # Run model tests only
bin/rails test test/controllers/  # Run controller tests only
```

### Linting & Security
```bash
bin/rubocop                       # Run RuboCop linter (Omakase style)
bin/rubocop -a                    # Auto-fix RuboCop offenses
bin/brakeman --no-pager           # Security vulnerability scanning
bin/bundler-audit                 # Gem security audit
```

### CI Pipeline (GitHub Actions)
The CI runs three jobs on PRs and pushes to `main`:
1. **scan_ruby** - `bin/brakeman` and `bin/bundler-audit`
2. **lint** - `bin/rubocop -f github`
3. **test** - `bin/rails db:test:prepare test` (with PostgreSQL service)

## Architecture

### API Structure
All endpoints are namespaced under `/api/v1/`:

| Method | Path | Controller | Auth Required |
|--------|------|-----------|---------------|
| POST | `/api/v1/auth/login` | `Api::V1::Auth::SessionsController` | No |
| DELETE | `/api/v1/auth/logout` | `Api::V1::Auth::SessionsController` | Yes |
| POST | `/api/v1/auth/signup` | `Api::V1::Auth::RegistrationsController` | No |
| GET | `/api/v1/profile` | `Api::V1::ProfilesController` | Yes |
| PATCH | `/api/v1/profile` | `Api::V1::ProfilesController` | Yes |
| GET | `/api/v1/posts` | (stub) | Yes |
| GET | `/up` | Health check | No |

### Authentication
- **Devise + JWT** tokens via `Authorization` header
- JWT tokens expire after 24 hours
- Token dispatch on `POST /api/v1/auth/login`
- Token revocation on `DELETE /api/v1/auth/logout` (stored in `jwt_denylists` table)
- JWT secret: `Rails.application.credentials.secret_key_base` or `DEVISE_JWT_SECRET_KEY` env var

### Authorization (RBAC)
Three-table model: `Role -> RolePermissionResource -> (Permission + Resource)`

Check permissions via `user.can?(permission_name, resource_name)` which queries the `role_permission_resources` join table.

### Database Models
Core models with key relationships:
- **User** - `belongs_to :role` (optional), has Devise authentication modules
- **Role** - `has_many :permissions` and `:resources` through `role_permission_resources`
- **Permission** / **Resource** - Referenced via `RolePermissionResource` junction
- **UserRole** - Many-to-many user-role assignment
- **JwtDenylist** - Revoked JWT tokens (Devise::JWT::RevocationStrategies::Denylist)
- **GroupCatalog** / **Catalog** / **Status** - Lookup value management

### Serialization
Uses `jsonapi-serializer` gem. Serializers live in `app/serializers/` and follow JSONAPI format. Access serialized data via:
```ruby
UserSerializer.new(resource).serializable_hash[:data][:attributes]
```

## Code Conventions

### Style
- **RuboCop**: Uses `rubocop-rails-omakase` (Rails Omakase style guide)
- **Frozen string literals**: Use `# frozen_string_literal: true` at the top of Ruby files
- **API responses**: All endpoints return JSON with a consistent structure:
  ```json
  {
    "status": { "code": 200, "message": "..." },
    "data": { ... }
  }
  ```
- Error responses include an `errors` array of full messages

### Patterns
- **Soft deletes**: All models use an `active` boolean column (default: `true`) with `scope :active, -> { where(active: true) }`
- **UUIDs**: All models have a `uuid` column generated via `gen_random_uuid()` (pgcrypto extension)
- **API versioning**: Controllers namespaced under `Api::V1::` in `app/controllers/api/v1/`
- **Controller indentation**: Auth controllers (sessions, registrations) use 4-space indentation; other controllers use 2-space indentation
- **Devise customization**: Custom controllers inherit from `Devise::SessionsController` or `Devise::RegistrationsController`, override `respond_with` and action methods

### Adding New Endpoints
1. Create controller under `app/controllers/api/v1/`
2. Add route inside the `namespace :api > namespace :v1` block in `config/routes.rb`
3. Protected routes go inside the `authenticate :user` block
4. Create a serializer in `app/serializers/` if returning model data
5. Add corresponding tests in `test/`

### Adding New Models
1. Generate migration with `uuid` column (`default: -> { "gen_random_uuid()" }`) and `active` boolean (`default: true`)
2. Add `scope :active` and relevant validations
3. Index the `uuid` (unique) and `active` columns

## Environment Configuration

### Required Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `DB_HOST` | PostgreSQL host | `db` (Docker) |
| `DB_USERNAME` | Database user | `postgres` |
| `DB_PASSWORD` | Database password | `postgres` |

### Optional Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `CORS_ORIGINS` | Allowed CORS origins (comma-separated) | `*` |
| `DEVISE_JWT_SECRET_KEY` | JWT signing key | Falls back to `credentials.secret_key_base` |
| `RAILS_LOG_LEVEL` | Log level | `info` |
| `SOLID_QUEUE_IN_PUMA` | Run Solid Queue in Puma | `true` |
| `REDIS_URL` | Redis connection URL | `redis://redis:6379/0` |

Development env vars are loaded via `dotenv-rails` from `.env` file.

## Infrastructure

### Docker
- **Production**: Multi-stage Dockerfile with Ruby 3.2.8-slim, jemalloc, Thruster on port 80
- **Development**: `.devcontainer/` with PostgreSQL 15 and Redis 7 services

### Deployment
- **Kamal** (`config/deploy.yml`) targeting Docker containers
- Service name: `workspace`, image served via local registry
- Background jobs: Solid Queue runs in-process with Puma (`SOLID_QUEUE_IN_PUMA=true`)

### Background Jobs
- **Solid Queue** (database-backed) with 3 worker threads and 1 dispatcher
- Configuration in `config/queue.yml`

## Testing

- Framework: **Minitest** (Rails default)
- Parallel execution enabled (`parallelize(workers: :number_of_processors)`)
- Fixtures loaded automatically from `test/fixtures/`
- Run with: `bin/rails test`
- CI uses `DATABASE_URL=postgres://postgres:postgres@localhost:5432`
