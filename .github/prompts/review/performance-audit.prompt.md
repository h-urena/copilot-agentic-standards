---
agent: agent
description: "Audit a codebase or PR for performance issues: N+1 queries, missing indexes, unbounded result sets, cache opportunities, and bundle size."
---

# Performance Audit

You are a performance audit agent. Load `skills/performance-profiling.skill.md` before proceeding. Work through each step in order.

## Step 1 — Establish scope and baseline

Before analysing anything:
- Identify which service(s) are in scope
- Identify the hot paths: endpoints or operations called > 100×/minute in production
- Record the current baseline if available: p50, p95, p99 latency, throughput (RPS), error rate

If no baseline data is available, note this — improvements cannot be quantified without a before/after.

## Step 2 — Database query analysis

For every database query in the diff or codebase (focus on hot paths):

### N+1 detection
```bash
# Search for loop + query patterns
grep -rn "await.*db\." src/ | head -50
grep -rn "for.*in.*:" src/ | head -50
```

Flag any pattern where a query appears inside a loop over a result set.

### Missing index check
For every `WHERE`, `ORDER BY`, `JOIN ON`, and `GROUP BY` column:
- [ ] Is there an index covering this column?
- [ ] Is the index a covering index (includes all selected columns)?
- [ ] For composite indexes, is the column order correct (equality conditions first, then ranges)?

### Unbounded result sets
Flag any query that:
- Fetches all rows without a `LIMIT`
- Returns a list endpoint with no pagination
- Loads entire related collections (ORM `include` / `eager_load`) when only IDs are needed

## Step 3 — Application-level analysis

### Serialisation hot spots
- Are there endpoints that serialise large objects on every request?
- Is JSON serialisation happening inside a tight loop?

### Caching opportunities
For each data fetch in the hot path, ask:
- How often does this data change? (read/write ratio)
- How stale can the data be before it causes a problem?
- Would an in-process cache (< 1 ms) or a distributed cache (Redis, 1–5 ms) be appropriate?

### Concurrent I/O
Flag sequential `await` calls that could be parallelised:
```typescript
// ❌ Sequential (unnecessary latency)
const user = await getUser(userId);
const orders = await getOrders(userId);

// ✅ Parallel
const [user, orders] = await Promise.all([getUser(userId), getOrders(userId)]);
```

## Step 4 — Frontend bundle analysis (TypeScript projects only)

```bash
# Analyse bundle composition
npx vite-bundle-visualizer
# or
npx @next/bundle-analyzer
```

Flag:
- Any dependency > 50 KB that could be lazy-loaded
- Full library imports when only individual functions are needed (`import _ from 'lodash'` vs `import debounce from 'lodash/debounce'`)
- Unoptimised images (non-WebP/AVIF, missing dimensions)

## Step 5 — Apply fixes directly

For each finding, apply the fix and add a comment explaining the change. Do not just report — fix.

Priority order:
1. N+1 queries (highest impact, usually easy to fix)
2. Missing indexes on hot query paths
3. Unbounded result sets (add pagination)
4. Caching opportunities
5. Bundle optimisation

## Step 6 — Produce the audit report

```markdown
## Performance Audit Report

**Scope:** <service / module / PR>
**Date:** <date>
**Baseline:** <p99 latency, throughput, or "not available">

### Critical findings (apply immediately)
| # | Finding | Location | Estimated impact | Fix applied |
|---|---------|----------|-----------------|-------------|

### High findings (apply this sprint)
| # | Finding | Location | Estimated impact | Fix applied |
|---|---------|----------|-----------------|-------------|

### Medium findings (track as issues)
| # | Finding | Location | Estimated impact | Issue |
|---|---------|----------|-----------------|-------|

### Passed checks
- [ ] No N+1 queries on hot paths
- [ ] All hot-path queries have covering indexes
- [ ] All list endpoints are paginated
- [ ] No synchronous I/O in async hot paths
- [ ] Bundle size within budget (if applicable)
```
