---
agent: agent
description: "Scaffold a CRUD API: routes, models, validation, service layer, tests, and migrations."
---

# Scaffold CRUD API

**Constraint:** Do not write any code until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
Resource:    [singular name, e.g. user / product / order]
Fields:      [name: type: required: default]
Relations:   [belongs-to | has-many | many-to-many]
Auth:        [which operations require auth, which roles]
Soft delete: [Yes | No]
</schema>

## 1. MODEL_RULES

| Field | Rule |
|---|---|
| `id` | UUID (preferred for distributed systems) |
| `created_at` | Set on insert; never updated |
| `updated_at` | Updated on every write |
| `deleted_at` | Nullable datetime (soft delete only) |
| Foreign keys | Indexed |
| Migration | Idempotent, reversible, version-controlled |

## 2. ENDPOINT_TABLE

| Method | Path | Success | Error |
|---|---|---|---|
| `GET` | `/api/v1/<resources>` | 200 | 400 (invalid filter) |
| `GET` | `/api/v1/<resources>/:id` | 200 | 404 |
| `POST` | `/api/v1/<resources>` | 201 | 400, 422 |
| `PUT` | `/api/v1/<resources>/:id` | 200 | 400, 404, 422 |
| `PATCH` | `/api/v1/<resources>/:id` | 200 | 400, 404, 422 |
| `DELETE` | `/api/v1/<resources>/:id` | 204 | 404 |

List endpoint must support: pagination (`?page=1&limit=20`; default ≤ 20), filtering, sorting (`?sort=created_at&order=desc`).

## 3. LAYER_STRUCTURE

| Layer | Responsibility |
|---|---|
| Routes / Controllers | HTTP: parse, validate, respond |
| Services | Business logic: rules, orchestration |
| Repositories | Data access: queries, mutations |

## 4. VALIDATION_TABLE

| Stack | Tool | Location |
|---|---|---|
| TypeScript | Zod | Co-located with route |
| Python | Pydantic `BaseModel` | `schemas/` module |
| C# | FluentValidation or Data Annotations | `Validators/` or request record |

## 5. TEST_REQUIREMENTS

| Test type | Required coverage |
|---|---|
| Unit (service layer) | Create, update, delete, not-found, auth failure |
| Integration (API layer) | One test per endpoint — Testcontainers for DB |
| Auth | Unauthenticated → 401; wrong role → 403; IDOR → 403 |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| DB queries in route handlers | Violates layering; untestable |
| Un-validated user input | Injection vector |
| Hardcoded pagination limit > 20 | Unbounded queries; DoS risk |
| Missing 404 on unknown ID | Leaks existence information or crashes |
| No IDOR check | Users can access other users' resources |