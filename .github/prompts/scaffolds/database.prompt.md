---
agent: agent
description: "Scaffold database setup: connection, ORM, migrations, repository pattern, health check."
---

# Scaffold Database Setup

**Constraint:** Do not write any code until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
Engine:     [PostgreSQL | SQL Server | MySQL | MongoDB | SQLite]
ORM:        [Prisma | Drizzle | TypeORM | SQLAlchemy | Django ORM | Tortoise | EF Core]
Migrations: [Built-in ORM | Alembic | Flyway | dbmate]
Pooling:    [Required for production: PgBouncer | built-in ORM pool | none]
Tenancy:    [Single DB | Schema-per-tenant | DB-per-tenant]
</schema>

## 1. ENV_VAR_SCHEMA

| Variable | Required | Description |
|---|---|---|
| `DATABASE_URL` | Yes | Full connection string |
| `DATABASE_POOL_SIZE` | Yes (production) | Explicit pool size |
| `DATABASE_POOL_TIMEOUT` | Yes (production) | Timeout in seconds |

**Constraint:** Connection string from environment variables only — never hardcoded. SSL/TLS required for remote connections. Validate at startup; fail fast if unreachable.

## 2. BASE_MODEL_FIELDS

| Field | Type | Rule |
|---|---|---|
| `id` | UUID | Preferred over auto-increment for distributed systems |
| `created_at` | Timestamp | Set on insert; never updated |
| `updated_at` | Timestamp | Updated on every write |
| `deleted_at` | Nullable Timestamp | Soft delete only |

## 3. MIGRATION_RULES

| Rule | Constraint |
|---|---|
| Versioned | Files in version control — never manual DB edits |
| Idempotent | Safe to run twice |
| Reversible | Down migration required |
| Destructive | Two-step: (1) stop reading column → (2) drop column |
| Shared env | Never modify a migration already applied to staging/prod |

## 4. LAYER_STRUCTURE

| Layer | Responsibility |
|---|---|
| Repository | Data access only — no business logic |
| Service | Orchestrates repositories; owns business rules |
| Health check | Verify DB connectivity at `/health` |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Hardcoded connection string | Credential exposure |
| No pool size config | Relies on defaults; starves production under load |
| Manual DB edits | Untracked schema drift |
| In-memory DB for integration tests | Different semantics; masks real bugs |
| Modifying applied migrations | Breaks reproducibility |
| Business logic in repository | Violates separation of concerns |