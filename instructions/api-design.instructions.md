---
applyTo: "**"
---

# API Design Standards

These rules apply to any service or module that exposes an HTTP API. Apply them at design time, not after.

## Resource-oriented URLs

- Use nouns, not verbs: `/orders`, not `/getOrders` or `/fetchOrder`
- Plural resource names: `/users/{id}`, `/products/{id}/variants`
- Nest to express ownership, maximum two levels: `/users/{id}/orders` — never `/users/{id}/orders/{orderId}/items/{itemId}/reviews`
- Actions that do not map cleanly to CRUD use a verb suffix on the resource: `POST /payments/{id}/refund`, `POST /users/{id}/deactivate`

## HTTP methods

| Method | Use | Notes |
|--------|-----|-------|
| GET | Read, no side effects | Must be safe and idempotent |
| POST | Create a new resource | Returns `201 Location` header |
| PUT | Full replacement of a resource | Idempotent |
| PATCH | Partial update | Use JSON Merge Patch (RFC 7396) |
| DELETE | Remove a resource | Returns `204` on success |

Never use GET for operations with side effects.

## Status codes

| Scenario | Code |
|----------|------|
| Created successfully | `201` + `Location` header |
| Accepted (async / background) | `202` + polling or webhook URL |
| No content (DELETE / action with no body) | `204` |
| Validation error (malformed request) | `400` |
| Unauthenticated | `401` |
| Forbidden (authenticated but not authorized) | `403` |
| Not found | `404` |
| Conflict (duplicate / business rule violation) | `409` |
| Unprocessable entity (semantic validation) | `422` |
| Rate limited | `429` + `Retry-After` header |
| Server error | `500` — never leak stack traces or internal messages |

## Request / response contracts

- Every API endpoint has a schema. Validate on receipt, before the request reaches business logic.
  - TypeScript: Zod
  - Python: Pydantic model
  - C#: data annotations + `ModelState.IsValid`, or FluentValidation
- Structured error body for all 4xx/5xx responses:
  ```json
  {
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Human-readable summary",
      "details": [{ "field": "email", "message": "must be a valid email address" }]
    }
  }
  ```
- Never return raw exception messages, stack traces, or internal identifiers to callers.
- Paginated list responses:
  ```json
  {
    "data": [...],
    "pagination": { "page": 1, "pageSize": 20, "total": 143, "totalPages": 8 }
  }
  ```

## Versioning

- Version in the URL path: `/v1/`, `/v2/`
- Never change the semantics of an existing version — add a new version instead
- Deprecate with response headers: `Deprecation: true` and `Sunset: <date>`
- Maintain at least one prior version for a documented deprecation window

## Query parameters

- Filtering: `?status=active&type=subscription`
- Sorting: `?sort=createdAt&order=desc`
- Pagination: `?page=2&pageSize=20` (1-indexed pages) or cursor-based: `?cursor=<opaque>&limit=20`
- Full-text search: `?q=<term>`
- Never use query params for write operations

## Performance

- Pagination is **required** on all list endpoints. Default page size ≤ 20; maximum ≤ 100.
- Avoid N+1: eager-load related resources or expose dedicated batch endpoints.
- Long-running operations (> ~2s): return `202` + a polling endpoint or use webhooks / SSE / WebSocket.
- Cache GET responses at the appropriate layer; set `Cache-Control` headers explicitly.

## Security

- Authenticate every non-public endpoint.
- Authorize at the resource level — verify the caller owns or has permission on the **specific resource**, not just that they are logged in (prevent IDOR).
- Rate-limit all public and authenticated endpoints.
- Sanitize all inputs; reject unknown fields at the schema level (`additionalProperties: false` / `model_config = ConfigDict(extra="forbid")` / `[JsonExtensionData]` avoided).
- CORS: explicit allow-list origins; never `*` in production for credentialed requests.
- `Content-Security-Policy`, `X-Content-Type-Options`, `X-Frame-Options` on all browser-facing responses.
