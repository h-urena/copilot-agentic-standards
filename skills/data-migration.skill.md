# Skill: Data Migration

This skill guides agents through planning and executing database schema migrations safely. Load this file when working on any migration — schema changes, data backfills, or column renames.

## The cardinal rules

1. **Never edit an applied migration.** Add a new one.
2. **Every migration must be reversible** (or explicitly documented as irreversible with a rollback plan).
3. **Zero-downtime migrations require multiple deployments.** Plan the rollout before writing any code.
4. **Test migrations on a production-size dataset** before applying to production.

## Migration risk assessment

Before writing any migration, classify it:

| Change | Risk | Strategy |
|--------|------|----------|
| Add nullable column | Low | Single deployment |
| Add column with default | Low | Single deployment |
| Add index (`CONCURRENTLY`) | Low | Single deployment (non-blocking) |
| Add NOT NULL column without default | **High** | Multi-phase (see below) |
| Rename column | **High** | Multi-phase |
| Rename table | **High** | Multi-phase |
| Remove column | Medium | Deprecate first, remove after 1+ sprint |
| Change column type | **High** | Multi-phase |
| Backfill large table | **High** | Batched backfill |

## Multi-phase migration pattern

For any high-risk change (rename, type change, NOT NULL enforcement):

### Phase 1 — Expand (deploy alongside current code)
- Add the **new column** (nullable, no constraint)
- Update application code to **write to both** old and new column
- Do **not** remove the old column

### Phase 2 — Backfill (can run while Phase 1 is deployed)
- Backfill the new column for all existing rows
- Use batches to avoid locking the table:
  ```sql
  -- PostgreSQL batched backfill (run until 0 rows updated)
  UPDATE users SET name_new = name_old
  WHERE id IN (
    SELECT id FROM users WHERE name_new IS NULL LIMIT 1000
  );
  ```

### Phase 3 — Contract (enforce constraint, remove old)
- Add `NOT NULL` constraint (after verifying 0 NULL rows)
- Update application code to **read and write only** the new column
- Deploy, then drop the old column in a follow-up migration

## Index creation (non-blocking)

Always create indexes `CONCURRENTLY` on production tables to avoid table locks:

```sql
-- PostgreSQL
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- Never (locks the table):
CREATE INDEX idx_orders_user_id ON orders(user_id);
```

Note: `CONCURRENTLY` cannot run inside a transaction. Mark the migration as non-transactional if your migration tool supports it.

## Backfill large tables safely

For tables with > 100k rows:
1. Process in batches of 1 000–10 000 rows
2. Add a small delay between batches (`pg_sleep(0.01)`) to release lock pressure
3. Track progress — log batch number and rows remaining
4. Make the backfill idempotent — safe to re-run if it fails mid-way

```python
# Python (SQLAlchemy) — safe batched backfill
BATCH_SIZE = 5000
while True:
    result = db.execute(
        text("""
            UPDATE users SET display_name = first_name || ' ' || last_name
            WHERE display_name IS NULL
            LIMIT :batch
        """),
        {"batch": BATCH_SIZE}
    )
    db.commit()
    if result.rowcount == 0:
        break
    time.sleep(0.05)  # yield to other queries
```

## Migration file requirements

Every migration file must include:
1. **Header comment** describing what and why (one paragraph)
2. **Up migration** (the change)
3. **Down migration** (the reversal) — or a comment explaining why rollback is not possible
4. Be idempotent where possible (`CREATE TABLE IF NOT EXISTS`, `IF NOT EXISTS` for indexes)

```sql
-- Migration: 20260421_add_display_name_to_users
-- Adds a pre-computed display_name column to avoid repeated string concatenation
-- in list queries. Backfilled in a separate migration (20260421_backfill_display_name).

-- Up
ALTER TABLE users ADD COLUMN display_name VARCHAR(255);

-- Down
ALTER TABLE users DROP COLUMN display_name;
```

## Pre-production checklist

Before applying to staging or production:

- [ ] Migration tested against a production-size data dump (or at least 10 % of prod row count)
- [ ] Estimated lock duration verified (use `EXPLAIN` on the migration SQL)
- [ ] Backfill estimated completion time calculated at expected batch throughput
- [ ] Rollback procedure documented
- [ ] Maintenance window scheduled if the migration cannot be zero-downtime
- [ ] DBA or team lead sign-off for high-risk changes
- [ ] Application code is already deployed that is compatible with both old and new schema (Expand phase)

## Post-migration verification

After applying:
- [ ] Run `SELECT COUNT(*) FROM table WHERE new_column IS NULL` — expect 0 for NOT NULL migrations
- [ ] Check application error rate — no spike in DB errors
- [ ] Check slow query log — no new slow queries introduced by the migration
- [ ] Confirm index was created with `\d table_name` (PostgreSQL) or `SHOW INDEX FROM table` (MySQL)
