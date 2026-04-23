# Skill: API Design Review

This skill guides agents through reviewing HTTP API design for correctness, consistency, and evolvability. Load this file when reviewing any PR that adds or changes API endpoints.

## Review checklist

### URL design

- [ ] URLs use **plural nouns**: `/users`, `/orders`, `/products` — not `/getUser`, `/fetchOrder`
- [ ] Resources are nested to express ownership, max 2 levels deep: `/users/{id}/orders` ✅ — never `/users/{id}/orders/{orderId}/items/{itemId}` ❌
- [ ] Actions that don't map to CRUD use a **verb suffix on the resource**: `POST /payments/{id}/refund` ✅ — never `POST /refundPayment` ❌
- [ ] Path parameters use `camelCase` or `kebab-case` consistently — never mix
- [ ] Query parameters use `camelCase`: `?pageSize=20&sortBy=createdAt`
- [ ] No verbs in the path for standard CRUD operations (`/create`, `/update`, `/delete`)

### HTTP method usage

| Check | ✅ Correct | ❌ Wrong |
|-------|-----------|---------|
| Reads have no side effects | `GET /users` returns list | `GET /users?action=delete` |
| Creates return 201 | `POST /users` → `201 Location: /users/{id}` | `POST /users` → `200` |
| Full updates are idempotent | `PUT /users/{id}` replaces entire resource | `PUT /users/{id}` does partial update |
| Partial updates use PATCH | `PATCH /users/{id}` with JSON Merge Patch | `POST /users/{id}/update` |
| Deletes return 204 | `DELETE /users/{id}` → `204 No Content` | `DELETE /users/{id}` → `200 { "success": true }` |

### Status code correctness

Verify every status code matches the scenario:

| Scenario | Expected code |
|----------|-------------|
| Successful create | `201` + `Location` header |
| Async operation accepted | `202` + polling URL |
| Success with no body | `204` |
| Invalid request shape | `400` |
| Missing or invalid auth token | `401` |
| Valid token, insufficient permissions | `403` |
| Resource does not exist | `404` |
| Business rule conflict (duplicate, state mismatch) | `409` |
| Semantic validation failure | `422` |
| Rate limited | `429` + `Retry-After` header |
| Unexpected server error | `500` (never leak details) |

### Request / response contracts

- [ ] Every request body is validated by a schema (Zod, Pydantic, FluentValidation) **before** reaching business logic
- [ ] Every error response follows the standard error shape:
  ```json
  { "error": { "code": "SCREAMING_SNAKE", "message": "Human text", "details": [] } }
  ```
- [ ] Paginated list responses include pagination metadata:
  ```json
  { "data": [...], "pagination": { "page": 1, "pageSize": 20, "total": 143 } }
  ```
- [ ] No nullable fields in responses that are always present — use proper optionality
- [ ] Response shapes are consistent across endpoints (same field names, same date formats)
- [ ] Dates are ISO 8601 with timezone: `"2026-04-21T14:30:00Z"`
- [ ] IDs are strings (UUIDs or opaque tokens) — never expose auto-increment integers

### Versioning

- [ ] New endpoints are under the current API version prefix (`/v1/`, `/v2/`)
- [ ] Breaking changes to an existing version create a **new version** — never change semantics in place
- [ ] Deprecated fields/endpoints include `Deprecation: true` and `Sunset: <date>` response headers

### Security review for APIs

- [ ] Every endpoint that returns user data checks resource ownership (IDOR prevention): does the requester own or have permission to access this specific resource?
- [ ] Admin-only endpoints require an explicit role/permission check — not just authentication
- [ ] Sensitive fields (`password`, `ssn`, `cardNumber`) are never returned in any response
- [ ] File upload endpoints validate MIME type **and** file content (not just the Content-Type header)
- [ ] Search endpoints paginate results — no unbounded result sets

### Rate limiting and abuse prevention

- [ ] Authentication endpoints (login, password reset) have rate limiting
- [ ] List/search endpoints have a maximum `pageSize` (suggest: 100)
- [ ] File upload endpoints have a size limit enforced at the API gateway or middleware layer

## Findings format

```
[BREAKING / DESIGN / SECURITY / STYLE] endpoint
Issue: <description>
Impact: <who is affected, how>
Fix: <what to change>
```
