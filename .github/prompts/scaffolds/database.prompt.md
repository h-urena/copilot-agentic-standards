---
agent: agent
description: "Set up a database: configure the connection, ORM, migrations, seeding, and health checks — following project standards for the detected stack."
---

# Scaffold Database Setup

You are a database setup agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Determine database requirements

Before creating any file, confirm:

- **Database engine:** PostgreSQL, SQL Server, MySQL, MongoDB, SQLite
- **ORM / query builder:** Prisma, Drizzle, TypeORM (TS) | SQLAlchemy, Django ORM, Tortoise (Python) | EF Core (C#)
- **Migration tool:** Built into ORM or standalone (Alembic, Flyway, dbmate)
- **Connection pooling:** Required for production (PgBouncer, built-in ORM pool)
- **Multi-tenancy:** Single DB, schema-per-tenant, or DB-per-tenant

## Step 2 — Configure the database connection

**Environment variables (all stacks):**
```env
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
DATABASE_POOL_SIZE=10
DATABASE_POOL_TIMEOUT=30
```

**TypeScript (Prisma)**
```typescript
// prisma/schema.prisma
datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}
```

**Python (SQLAlchemy)**
```python
# src/db/engine.py
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

engine = create_async_engine(
    settings.DATABASE_URL,
    pool_size=settings.DATABASE_POOL_SIZE,
    pool_timeout=settings.DATABASE_POOL_TIMEOUT,
)
async_session = async_sessionmaker(engine, expire_on_commit=False)
```

**C# (EF Core)**
```csharp
// Program.cs
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("Default")));
```

**Rules:**
- Connection string from environment variables — never hardcoded.
- Pool size configured explicitly — never rely on defaults in production.
- SSL/TLS required for remote connections.
- Validate config at startup — fail fast if the database is unreachable.

## Step 3 — Set up the migration framework

**TypeScript (Prisma)**
```bash
npx prisma migrate dev --name init
```

**Python (Alembic)**
```bash
alembic init alembic
alembic revision --autogenerate -m "initial schema"
alembic upgrade head
```

**C# (EF Core)**
```bash
dotnet ef migrations add InitialCreate
dotnet ef database update
```

**Migration rules:**
- Migrations are versioned files in version control — never manually edit the database.
- Every migration is idempotent and reversible (include `down` / rollback).
- Test migrations locally before merging.
- Destructive migrations (drop column/table) require a two-step approach:
  1. Deploy code that stops reading the column.
  2. Deploy migration that drops the column.
- Never modify a migration that has been applied to a shared environment.

## Step 4 — Create the base model and repository pattern

**Base model (shared fields):**
```
id          — UUID or auto-increment (prefer UUID for distributed systems)
created_at  — Timestamp, set on insert, never updated
updated_at  — Timestamp, updated on every write
deleted_at  — Nullable timestamp (for soft deletes)
```

**Repository pattern:**
```
repositories/
  base.repository.ts      — Generic CRUD operations
  <resource>.repository.ts — Resource-specific queries
```

**Rules:**
- Repositories handle data access only — no business logic.
- Use `.AsNoTracking()` (C#) or equivalent for read-only queries.
- Parameterized queries only — never string interpolation in SQL.
- Pagination required on all list queries (default limit ≤ 20).
- Indexes on: primary keys, foreign keys, frequently filtered/sorted columns.

## Step 5 — Set up seed data

Create a seeding mechanism for development and testing:

```
src/db/seeds/
  001-roles.ts           — Reference data (roles, permissions, statuses)
  002-test-users.ts      — Development-only test users
```

**Rules:**
- Seed scripts are idempotent (safe to run multiple times).
- Never seed production data with hardcoded passwords.
- Separate reference data (roles, categories) from test data (fake users, sample products).

## Step 6 — Configure Docker Compose for local development

Add the database to `docker-compose.yml`:

```yaml
services:
  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_DB: mydb
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    ports:
      - "5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U myuser -d mydb"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  db-data:
```

## Step 7 — Add health check endpoint

Expose a health check that verifies database connectivity:

```
GET /health
{
  "status": "healthy",
  "checks": {
    "database": { "status": "healthy", "latency_ms": 2 }
  }
}
```

## Step 8 — Write database tests

**Integration tests (Testcontainers — real database):**
- Migration applies cleanly to empty database
- CRUD operations work end-to-end
- Pagination, filtering, sorting behave correctly
- Soft delete excludes records from default queries
- Concurrent writes don't cause data corruption
- Connection pool handles expected load

## Step 9 — Commit database setup

```bash
git add -A
git commit -m "feat(db): configure <engine> with <ORM> and migrations

- Connection pooling and environment-based config
- Initial migration with base schema
- Repository pattern with generic CRUD
- Seed data for development
- Docker Compose for local database
- Health check endpoint
- Integration tests with Testcontainers

Closes #<issue-number>"
```
