---
applyTo: "**"
---

# Observability Standards

Every service must be observable from day one. Observability is not a post-launch concern.

## The three pillars

| Pillar | What it answers | Tooling standard |
|--------|----------------|-----------------|
| **Logs** | What happened? | Structured JSON — `pino` (TS), `structlog` (Python), `Serilog` (C#) |
| **Traces** | Where did time go? | OpenTelemetry SDK + OTLP exporter |
| **Metrics** | Is the system healthy? | OpenTelemetry metrics or Prometheus client |

## Structured logging

**Rules:**

- All log output is JSON. No plain-text log lines in production.
- Every log line at `INFO` or above includes: `timestamp`, `level`, `service`, `traceId`, `spanId`.
- Never log PII (email addresses, names, passwords, tokens, card numbers).
- Never log full request or response bodies. Log a summary or omit.
- Do not use `console.log`, `print()`, or `Debug.WriteLine()` in production code paths — use the structured logger.

**Log levels — use precisely:**

| Level | When to use |
|-------|-------------|
| `ERROR` | Unexpected failure that requires human attention. Always include the full exception / stack trace. |
| `WARN` | Expected condition that indicates potential problems (retrying, degraded mode, approaching limit). No stack trace unless useful. |
| `INFO` | Significant business events (user registered, payment processed, job completed). One line per event. |
| `DEBUG` | Diagnostic details useful during development. Must never appear in production at steady state. |

**Request-scoped context:**

Attach `traceId`, `requestId`, and `userId` (when authenticated) to every log emitted during a request. Use logger child instances or scoped loggers — never pass these values as individual function parameters.

```typescript
// TypeScript (pino)
const reqLogger = logger.child({ traceId, requestId, userId });
```

```python
# Python (structlog)
log = structlog.get_logger().bind(trace_id=trace_id, request_id=request_id)
```

```csharp
// C# (Serilog)
using var scope = Log.ForContext("TraceId", traceId).ForContext("RequestId", requestId);
```

## Distributed tracing

- Instrument every service with the **OpenTelemetry SDK** for the language.
- Propagate `traceparent` / `tracestate` headers across all HTTP calls and message queue messages.
- Create a span for every external I/O: HTTP calls, DB queries, cache reads, queue publishes.
- Name spans with verb-noun: `GET /users/{id}`, `db.query users`, `cache.get session`.
- Export traces via OTLP to your collector (Jaeger, Tempo, Datadog, etc.).

## Metrics

Every service must expose these minimum metrics:

| Metric | Type | Labels |
|--------|------|--------|
| `http_request_duration_seconds` | Histogram | `method`, `route`, `status_code` |
| `http_requests_total` | Counter | `method`, `route`, `status_code` |
| `db_query_duration_seconds` | Histogram | `operation`, `table` |
| Custom business metric (e.g. `orders_created_total`) | Counter | relevant dimensions |

Use p50 / p95 / p99 latency percentiles, not averages, for SLO tracking.

## Health checks

Every HTTP service must expose two endpoints:

| Endpoint | Purpose | Returns `200` when |
|----------|---------|-------------------|
| `GET /health` | **Liveness** — is the process alive? | Process is running (no DB check) |
| `GET /ready` | **Readiness** — can it serve traffic? | DB connection pool healthy, cache reachable |

The readiness check must be used as the Kubernetes `readinessProbe` / Docker healthcheck target.

## Alerting thresholds (baseline)

Configure alerts for these conditions in any production environment:

- Error rate > 1 % over 5 minutes
- p99 latency > 2 × normal baseline over 5 minutes
- Readiness check failing for > 1 minute
- Memory usage > 85 % of container limit
- Disk usage > 80 %

## What NOT to do

- Do not log at `DEBUG` in production steady state — it creates noise and cost.
- Do not catch exceptions silently and log only at `WARN` when the error is unrecoverable.
- Do not use correlation IDs that are not propagated across service boundaries.
- Do not create metrics with unbounded cardinality (e.g. using user IDs as label values).
