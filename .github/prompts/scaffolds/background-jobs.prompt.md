---
agent: agent
description: "Scaffold async background jobs: queue setup, job definition, retry policy, dead-letter handling, monitoring."
---

# Scaffold Background Jobs

**Constraint:** Do not write any code until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
Trigger:    [Event (queue) | Schedule (cron) | Manual (API)]
Operation:  [one sentence description]
Idempotent: [Yes | No — if No, explain why]
Duration:   [< 1 s | 1–60 s | > 60 s (needs heartbeat)]
Priority:   [Single queue | Fast + slow lanes]
Retry:      [max attempts | backoff strategy | dead-letter destination]
</schema>

## 1. STACK_TABLE

| Stack | Queue | Package |
|---|---|---|
| TypeScript | BullMQ (Redis) | `bullmq` |
| Python | Celery (Redis / RabbitMQ) | `celery[redis]` |
| C# | MassTransit (RabbitMQ / Azure Service Bus) | `MassTransit` |

## 2. JOB_CONTRACT_RULES

| Rule | Constraint |
|---|---|
| Payload content | IDs only — no domain objects or DB entities |
| serialization | JSON only |
| Idempotency key | Required — job must be safe to run twice with same input |
| Payload schema | Typed: `interface` (TS) / `BaseModel` (Python) / `record` (C#) |

## 3. RETRY_SCHEMA

| Field | Required value |
|---|---|
| Max attempts | Explicit number |
| Backoff | Exponential with jitter |
| Dead-letter queue | Named destination for permanently failed jobs |
| Alert | Alert fired when job lands in DLQ |

## 4. OUTPUT_STRUCTURE

| File | Purpose |
|---|---|
| `src/jobs/queue.ts` / `app/worker/celery.py` / `Program.cs` | Queue connection |
| `src/jobs/<name>.job.ts` / `app/worker/tasks/<task>.py` / `Consumers/<Name>Consumer.cs` | Job definition |
| `src/jobs/<name>.job.test.ts` / `tests/worker/test_<task>.py` / `Tests/<Name>ConsumerTests.cs` | Job unit tests |

## 5. MONITORING_REQUIREMENTS

| Check | Required |
|---|---|
| Job enqueued | Logged at INFO with job ID and payload size |
| Job started | Logged at INFO |
| Job succeeded | Logged at INFO with duration |
| Job failed | Logged at ERROR with attempt number and reason |
| DLQ alert | Fired on first failure landing in DLQ |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Domain objects in job payload | serialization drift; stale data |
| No idempotency | Double-processing on retry causes data corruption |
| No dead-letter queue | Failed jobs disappear silently |
| Inline job logic in queue setup | Untestable |
| `time.sleep` in worker | Blocks thread; use queue delay instead |