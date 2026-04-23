---
agent: agent
description: "Scaffold a notifications system: email, webhooks, and/or push notifications — with queuing, retry, and opt-out."
---

# Scaffold Notifications

You are a notifications scaffolding agent. Work through the steps below in order.

## Step 1 — Confirm requirements

Before writing any code:

- **Channels required:** Email / Webhook / Web push / Mobile push / SMS / Slack
- **Trigger model:** User action triggers notification / scheduled digest / threshold alert
- **Template ownership:** System-defined templates / user-customisable
- **User preferences:** Can users opt out of notification types?
- **Delivery guarantees:** At-most-once (fire and forget) or at-least-once (queue-backed with retry)?

## Step 2 — Notification domain model

Define the core entities:

```typescript
// TypeScript
interface Notification {
  id: string;
  userId: string;
  channel: 'email' | 'webhook' | 'push';
  type: string;           // e.g. 'order.shipped', 'invoice.due'
  payload: Record<string, unknown>;
  status: 'pending' | 'sent' | 'failed' | 'skipped';
  createdAt: Date;
  sentAt?: Date;
  failureReason?: string;
}

interface UserNotificationPreference {
  userId: string;
  channel: 'email' | 'webhook' | 'push';
  type: string;
  enabled: boolean;
}
```

## Step 3 — Notification service layer

```typescript
// src/notifications/notification.service.ts
export class NotificationService {
  async send(userId: string, type: string, payload: Record<string, unknown>): Promise<void> {
    // 1. Check user preferences — skip if opted out
    const prefs = await this.prefRepo.findAll(userId, type);
    if (prefs.every(p => !p.enabled)) return;

    // 2. Persist notification record (pending status)
    const notification = await this.notifRepo.create({ userId, type, payload, status: 'pending' });

    // 3. Enqueue for delivery (do not deliver inline — use queue)
    await this.queue.add('send-notification', { notificationId: notification.id });
  }
}
```

## Step 4 — Email

**Provider:** Resend (recommended) / SendGrid / AWS SES / Postmark

```typescript
// src/notifications/channels/email.channel.ts
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendEmail(to: string, subject: string, html: string): Promise<void> {
  const { error } = await resend.emails.send({
    from: process.env.EMAIL_FROM!,   // e.g. 'App <noreply@example.com>'
    to,
    subject,
    html,
  });
  if (error) throw new Error(`Email send failed: ${error.message}`);
}
```

**Templates:** Store templates as files, not database rows, unless users can customise them.

```
src/notifications/templates/
├── order-shipped.tsx       # React Email template (TypeScript)
├── invoice-due.tsx
└── ...
```

## Step 5 — Webhooks

```typescript
// src/notifications/channels/webhook.channel.ts
import crypto from 'crypto';

export async function deliverWebhook(
  url: string,
  secret: string,
  event: string,
  payload: unknown,
): Promise<void> {
  const body = JSON.stringify({ event, payload, timestamp: new Date().toISOString() });
  const signature = crypto.createHmac('sha256', secret).update(body).digest('hex');

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Signature-SHA256': `sha256=${signature}`,
      'X-Event-Type': event,
    },
    body,
    signal: AbortSignal.timeout(10_000),  // 10 s timeout
  });

  if (!response.ok) {
    throw new Error(`Webhook delivery failed: ${response.status} ${response.statusText}`);
  }
}
```

**Receiver verification (for incoming webhooks from third parties):**
```typescript
function verifyWebhookSignature(body: string, signature: string, secret: string): boolean {
  const expected = `sha256=${crypto.createHmac('sha256', secret).update(body).digest('hex')}`;
  return crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expected));
}
```

## Step 6 — Retry policy

All delivery failures should retry with exponential backoff:
- Attempt 1: immediately
- Attempt 2: after 30 s
- Attempt 3: after 5 min
- Attempt 4: after 30 min
- Attempt 5: after 2 h
- After 5 attempts: mark as `failed`, add to dead-letter queue, alert

```typescript
// BullMQ retry config
{ attempts: 5, backoff: { type: 'exponential', delay: 30_000 } }
```

## Step 7 — User preferences API

```
GET  /api/notification-preferences          → list user's preferences
PUT  /api/notification-preferences/:type    → update channel settings for a type
```

Store opt-out preferences in DB. Default is **opted in** — only store exceptions.

## Step 8 — Database migrations

```sql
-- notifications table
CREATE TABLE notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID NOT NULL REFERENCES users(id),
  channel     TEXT NOT NULL,
  type        TEXT NOT NULL,
  payload     JSONB NOT NULL,
  status      TEXT NOT NULL DEFAULT 'pending',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  sent_at     TIMESTAMPTZ,
  failure_reason TEXT
);

CREATE INDEX notifications_user_id_idx ON notifications(user_id);
CREATE INDEX notifications_status_idx ON notifications(status) WHERE status = 'pending';

-- preferences table
CREATE TABLE notification_preferences (
  user_id     UUID NOT NULL REFERENCES users(id),
  channel     TEXT NOT NULL,
  type        TEXT NOT NULL,
  enabled     BOOLEAN NOT NULL DEFAULT true,
  PRIMARY KEY (user_id, channel, type)
);
```

## Step 9 — Tests to write

- Unit: notification service skips delivery when user opted out
- Unit: webhook channel attaches correct HMAC signature
- Unit: email channel uses correct template for each notification type
- Integration: enqueue notification → worker processes it → status updated to `sent`
- Integration: delivery failure → job retries → after max attempts → status `failed`
