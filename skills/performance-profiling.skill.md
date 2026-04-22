# Skill: Performance Profiling

This skill guides agents through systematic performance analysis. Load this file when investigating a performance issue or conducting a performance audit.

## Phase 1 — Establish a baseline

Before any optimisation:
1. **Measure first, optimise second.** Never optimise without data.
2. Identify the metric that matters to users: latency (p99), throughput (RPS), or resource cost (CPU/memory).
3. Record the baseline: `p50 = Xms, p95 = Yms, p99 = Zms` under N RPS.
4. Identify the hot path: the code executed on every request / operation.

## Phase 2 — Database query analysis

Database queries are the most common performance bottleneck. Check every query in the hot path.

### N+1 detection

```
// ❌ N+1: fetches 1 order, then N product queries (one per order item)
const orders = await db.orders.findMany();
for (const order of orders) {
  order.items = await db.orderItems.findMany({ where: { orderId: order.id } });
}

// ✅ Single query with JOIN / include
const orders = await db.orders.findMany({ include: { items: true } });
```

Signs of N+1:
- A loop that contains a DB call
- ORM lazy-loading enabled in a list endpoint
- Logs showing 50+ queries for a single HTTP request

### Query plan analysis

For any slow query (> 100 ms), run `EXPLAIN ANALYZE` and look for:
- **Sequential scans** on large tables → add an index
- **High row estimates vs actual** → run `ANALYZE` to update statistics
- **Nested loop joins** on large datasets → may need a hash join hint or different query shape
- **Sort operations without index** → add a covering index for ORDER BY columns

### Index checklist

| Situation | Action |
|-----------|--------|
| Filtering by a column in `WHERE` | Add a single-column index |
| Filtering and sorting by different columns | Add a composite index `(filter_col, sort_col)` |
| Full-text search | Add a GIN index (PostgreSQL) |
| JSONB queries | Add a GIN index on the JSONB column |
| Foreign key joins | Ensure the FK column is indexed (many ORMs don't do this automatically) |
| Very high write rate | Evaluate whether the index cost outweighs the read benefit |

## Phase 3 — Application-level analysis

### Memory and allocations

- Identify objects allocated inside tight loops that could be pre-allocated or reused
- Look for large intermediate data structures (loading 10 MB into memory when streaming is possible)
- Check for memory leaks: event listeners not removed, caches without eviction policies, long-lived references in closures

### Serialisation and I/O

- Are large JSON payloads serialised/deserialised on every request when they could be cached?
- Are file reads/writes buffered or streaming appropriately?
- Are connection pools configured with sensible min/max sizes?

### Caching opportunities

Apply caching when:
- The data is read much more than it is written (> 10:1 read/write ratio)
- The data is expensive to compute or fetch
- Serving stale data for a short TTL is acceptable

Cache layer selection:
| Data | Cache | TTL |
|------|-------|-----|
| User session | Redis | Session lifetime |
| Feature flags | In-process (memory) | 1 minute |
| Static reference data (country list) | In-process | 1 hour |
| Computed aggregates | Redis | 5–60 minutes |
| API responses to third parties | Redis | As per their cache headers |

### Async and concurrency

- Independent I/O operations should run concurrently (`Promise.all`, `asyncio.gather`, `Task.WhenAll`)
- CPU-bound work belongs in a worker thread / process pool, not the event loop
- Avoid blocking the event loop with synchronous operations (file reads, crypto without async APIs)

## Phase 4 — Frontend / bundle performance (TypeScript only)

- Run `npx vite-bundle-visualizer` or equivalent to identify large chunks
- Lazy-load routes and heavy components (`React.lazy`, `next/dynamic`)
- Check that third-party libraries are tree-shaken (no full lodash import)
- Verify images use next-gen formats (WebP/AVIF) and have `width`/`height` set
- Check Core Web Vitals: LCP < 2.5 s, CLS < 0.1, FID/INP < 200 ms

## Phase 5 — Reporting

For each finding:

```
[CRITICAL / HIGH / MEDIUM / LOW] <component or query>
Observed: <baseline metric>
Root cause: <what is slow and why>
Evidence: <query plan, profiler output, benchmark result>
Fix: <specific change>
Expected improvement: <estimated impact>
```

Only propose optimisations with measurable expected impact. Speculative micro-optimisations without a proven bottleneck are not findings.
