---
agent: agent
description: "Scaffold a notifications system: channels, queuing, retry, opt-out, and delivery guarantees."
---

# Scaffold Notifications

**Constraint:** Do not write any code until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
Channels:  [Email | Webhook | Web push | Mobile push | SMS | Slack]
Trigger:   [User action | Scheduled digest | Threshold alert]
Templates: [System-defined | User-customisable]
Opt-out:   [Yes (per channel + per type) | No]
Delivery:  [At-most-once (fire-and-forget) | At-least-once (queue + retry)]
</schema>

## 1. DOMAIN_MODEL

| Entity | Required fields |
|---|---|
| `Notification` | `id` `userId` `channel` `type` `payload` `status` `createdAt` `sentAt?` `failureReason?` |
| `UserNotificationPreference` | `userId` `channel` `type` `enabled` |

`status` values: `pending` | `sent` | `failed` | `skipped`

## 2. SERVICE_RULES

| Rule | Constraint |
|---|---|
| Preference check | Check opt-out before any delivery attempt |
| Persist before send | Write `pending` record before enqueuing |
| Queue-backed | Never deliver inline — always enqueue |
| Idempotency | Delivery worker is safe to retry with same notification ID |

## 3. CHANNEL_TABLE

| Channel | Provider (recommended) | Env vars required |
|---|---|---|
| Email | Resend / SendGrid / AWS SES | `RESEND_API_KEY` `EMAIL_FROM` |
| Webhook | Custom HMAC-signed POST | `WEBHOOK_SECRET` |
| Web push | Web Push Protocol (VAPID) | `VAPID_PUBLIC_KEY` `VAPID_PRIVATE_KEY` |

**Webhook signing:** Sign payloads with HMAC-SHA256. Header: `X-Signature-SHA256: sha256=<hex>`. Receivers must verify with `timingSafeEqual`.

## 4. RETRY_SCHEMA

| Field | Required |
|---|---|
| Max attempts | Explicit number |
| Backoff | Exponential with jitter |
| Dead-letter | Named destination; alert on first arrival |
| `failureReason` | Written to notification record on each failure |

## 5. TEST_REQUIREMENTS

| Test | Required |
|---|---|
| Opted-out user | Notification skipped; no delivery attempt |
| Opted-in user | Notification enqueued |
| Delivery success | Status updated to `sent` |
| Delivery failure + retry | Status updated; `failureReason` recorded |
| DLQ arrival | Alert fired |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Inline delivery (no queue) | Single failure loses notification permanently |
| No opt-out support | Legal requirement in most jurisdictions (CAN-SPAM, GDPR) |
| Hardcoded provider API keys | Credential exposure |
| No idempotency in delivery worker | Double-sends on retry |
| Template HTML in source code strings | Unmaintainable; use template files |