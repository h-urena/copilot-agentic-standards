---
applyTo: "**"
---

# Database Patterns

These rules apply to any module that reads from or writes to a persistent data store.

## Migrations

- All schema changes are made via versioned migration files — never by editing the database directly.
  - Python: Alembic
  - TypeScript: Prisma Migrate, Drizzle Kit, or Flyway
  - C#: EF Core code-first migrations
- Migration files are committed to source control and reviewed in PRs like any other code.
- Migrations must be idempotent where the tooling supports it.
- Never edit a migration that has already been applied to any shared environment — add a new one.
- Document the intent of non-trivial migrations in a comment at the top of the file.

## Parameterised queries only

No string concatenation or template literal interpolation for query values — ever.

```python
# Python (SQLAlchemy) — correct
result = session.execute(text("SELECT * FROM users WHERE id = :id"), {"id": user_id})

# Python — WRONG (SQL injection)
result = session.execute(f"SELECT * FROM users WHERE id = {user_id}")
```

```ts
// TypeScript (Prisma) — correct
const user = await prisma.user.findUnique({ where: { id } });

// TypeScript (raw) — correct
await prisma.$queryRaw`SELECT * FROM users WHERE id = ${id}`;

// TypeScript — WRONG
await prisma.$queryRawUnsafe(`SELECT * FROM users WHERE id = '${id}'`);
```

```csharp
// C# (EF Core) — correct
var user = await db.Users.Where(u => u.Id == id).FirstOrDefaultAsync(ct);

// C# (raw) — correct
var user = await db.Users.FromSqlRaw("SELECT * FROM Users WHERE Id = {0}", id).FirstAsync(ct);

// C# — WRONG
var user = await db.Users.FromSqlRaw($"SELECT * FROM Users WHERE Id = '{id}'").FirstAsync(ct);
```

## Read vs write patterns

- Mark read queries as read-only to avoid unnecessary change tracking overhead:
  - EF Core: `.AsNoTracking()` or `.AsNoTrackingWithIdentityResolution()`
  - SQLAlchemy: `session.execute(..., execution_options={"readonly": True})`
  - Prisma: default (no tracking); use `$transaction` only when needed
- Wrap multi-step write operations in an explicit transaction.
- Keep transactions short — commit or roll back as quickly as possible to minimise lock contention.
- Do not hold transactions open across HTTP calls or user interactions.

## N+1 prevention

- Eager-load associations you know you will use.
  - EF Core: `.Include()` / `.ThenInclude()`
  - SQLAlchemy: `selectinload()` / `joinedload()`
  - Prisma: `include` option
- Enable query logging in development to detect unexpected N+1 patterns.
- Pagination is mandatory on all list queries — never load an unbounded result set.
- For bulk operations, prefer batch queries over per-row operations.

## Connection management

- Use a connection pool — never create raw connections per request.
  - Python: SQLAlchemy engine with `pool_size` and `max_overflow` configured
  - TypeScript: Prisma manages its own pool; Drizzle uses `postgres` or `pg` pool config
  - C#: EF Core + `IDbContextFactory<T>` or scoped `DbContext` per request (never singleton)
- Close / dispose connections promptly. Use `async with session`, `await using var db`, etc.

## Indexing

- Index every foreign key column.
- Index columns used in `WHERE`, `ORDER BY`, or `JOIN` clauses that are queried frequently.
- Document index decisions in the migration file: explain what query pattern the index supports.
- Avoid over-indexing — each index slows down writes and increases storage.
- Monitor slow query logs in production; add indexes reactively when query plans degrade.

## Soft deletes

- Use a `deleted_at TIMESTAMP` column — not a boolean `is_deleted`.
- Apply a global query filter to exclude soft-deleted rows:
  - EF Core: `modelBuilder.Entity<T>().HasQueryFilter(e => e.DeletedAt == null)`
  - SQLAlchemy: include in base query or use a hybrid attribute
  - Prisma: add middleware or use a `where` clause convention
- Expose a separate admin/audit path if deleted records must be accessible.

## Safety rules

- Never run `DROP TABLE` or `DROP COLUMN` migrations without a backup confirmed and a rollback plan documented in the PR.
- Test rollback of every migration locally before merging.
- Destructive migrations (column removal, data backfills) require a separate deploy window with a feature flag.
