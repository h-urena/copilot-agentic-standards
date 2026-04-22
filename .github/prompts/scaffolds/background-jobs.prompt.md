---
agent: agent
description: "Scaffold an async background job / worker: queue setup, job definition, retry policy, dead-letter handling, and monitoring."
---

# Scaffold Background Jobs

You are a background job scaffolding agent. Work through the steps below in order.

## Step 1 — Determine requirements

Before writing any code, confirm:

- **What triggers the job?** Event (message on queue), schedule (cron), or manual trigger (API call)?
- **What does the job do?** Describe the operation in one sentence.
- **Idempotency requirement:** Can the job run twice with the same input safely?
- **Expected duration:** < 1 s (micro-job) / 1–60 s (standard) / > 60 s (long-running, needs heartbeats)
- **Priority:** Is there a fast lane and a slow lane?
- **Failure tolerance:** How many retries? What happens to permanently failed jobs?

## Step 2 — Choose the stack-appropriate queue

| Stack | Recommended queue | Package |
|-------|------------------|---------|
| TypeScript | BullMQ (Redis-backed) | `bullmq` |
| Python | Celery (Redis or RabbitMQ) | `celery[redis]` |
| C# | MassTransit (RabbitMQ / Azure Service Bus) | `MassTransit` |

For simple cron-only jobs with no queue: use the process scheduler directly.

## Step 3 — Scaffold the queue connection

**TypeScript (BullMQ)**
```typescript
// src/jobs/queue.ts
import { Queue, Worker, QueueEvents } from 'bullmq';
import { redis } from '../lib/redis';

export const emailQueue = new Queue('email', { connection: redis });
```

**Python (Celery)**
```python
# app/worker/celery.py
from celery import Celery

celery_app = Celery(
    "app",
    broker=settings.REDIS_URL,
    backend=settings.REDIS_URL,
    include=["app.worker.tasks"],
)
celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
)
```

**C# (MassTransit + RabbitMQ)**
```csharp
// Program.cs
builder.Services.AddMassTransit(x =>
{
    x.AddConsumer<SendEmailConsumer>();
    x.UsingRabbitMq((ctx, cfg) =>
    {
        cfg.Host(builder.Configuration["RabbitMQ:Host"]);
        cfg.ConfigureEndpoints(ctx);
    });
});
```

## Step 4 — Define the job / message contract

Keep job payloads small and serialisable. Never put domain objects or DB entities in the payload — put IDs.

```typescript
// TypeScript
interface SendEmailJob {
  userId: string;
  templateId: string;
  variables: Record<string, string>;
}
```

```python
# Python
from pydantic import BaseModel

class SendEmailJob(BaseModel):
    user_id: str
    template_id: str
    variables: dict[str, str]
```

```csharp
// C#
public record SendEmailMessage(Guid UserId, string TemplateId, Dictionary<string, string> Variables);
```

## Step 5 — Implement the worker / consumer

**Idempotency pattern:** Every job must be safe to process more than once.
- Use a database record keyed by `jobId` to track completion
- Skip if already processed: `if (await db.jobLog.exists({ jobId })) return;`

**Retry policy:**
- Transient failures (network, DB connection): retry up to 5 times with exponential backoff
- Business errors (user not found, invalid state): do NOT retry — move to dead-letter

```typescript
// TypeScript worker with retry and DLQ
const worker = new Worker<SendEmailJob>('email', async (job) => {
  const { userId, templateId, variables } = job.data;
  const user = await userRepo.findById(userId);
  if (!user) throw new UnrecoverableError(`User ${userId} not found`);
  await emailService.send({ to: user.email, templateId, variables });
}, {
  connection: redis,
  attempts: 5,
  backoff: { type: 'exponential', delay: 1000 },
});
```

## Step 6 — Add dead-letter queue handling

Failed jobs that exhaust retries must go to a dead-letter queue (DLQ), not silently disappear.

- Configure DLQ for each queue
- Alert on DLQ depth > 0
- Build a simple admin UI or script to inspect and requeue DLQ messages

## Step 7 — Add health monitoring

Every worker process must expose:
- A liveness signal (heartbeat every 30 s to Redis or DB)
- Queue depth metric (jobs waiting / jobs active / jobs failed)
- Job processing latency histogram

## Step 8 — Add to Docker Compose

```yaml
services:
  worker:
    build: .
    command: ["node", "dist/worker.js"]  # or celery worker / dotnet WorkerService
    environment:
      REDIS_URL: redis://redis:6379
    depends_on:
      redis:
        condition: service_healthy
    restart: unless-stopped
    deploy:
      replicas: 2  # run multiple instances for throughput
```

## Step 9 — Write tests

- Unit test the job handler with mocked dependencies (DB, email service)
- Integration test: enqueue a real job → verify it processes → verify side effects
- Test idempotency: process the same job twice → verify no duplicate side effects
- Test retry: simulate transient failure → verify job retries and eventually succeeds
- Test DLQ: simulate permanent failure → verify job lands in dead-letter queue
