---
agent: agent
description: "Scaffold a CRUD API: routes, models, validation, tests, and database migrations — following project standards for the detected stack."
---

# Scaffold CRUD API

You are an API scaffolding agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Gather resource requirements

Before creating any file, determine:

- **Resource name** (singular): e.g., `user`, `product`, `order`
- **Fields** with types, constraints, and defaults
- **Relationships** to other resources (belongs-to, has-many, many-to-many)
- **Auth requirements** — which operations require auth? What roles?
- **Soft delete** — should the resource support soft deletion?

## Step 2 — Create the data model and migration

**TypeScript (Prisma / Drizzle / TypeORM)**
```
src/models/<resource>.ts        — Type/interface definition
prisma/migrations/              — or equivalent migration directory
```

**Python (SQLAlchemy / Django / Tortoise)**
```
src/models/<resource>.py        — SQLAlchemy model
alembic/versions/               — or Django migration
```

**C# (EF Core)**
```
src/Models/<Resource>.cs        — Entity class
src/Data/Migrations/            — EF Core migration
```

**Rules:**
- Every model has `id`, `created_at`, `updated_at` fields.
- Soft delete adds `deleted_at` (nullable datetime).
- Foreign keys have corresponding indexes.
- Migration is idempotent and reversible.

## Step 3 — Create the validation schema

Validate all input at the boundary — never inside business logic.

**TypeScript** — Zod schemas co-located with the route:
```typescript
const CreateResourceSchema = z.object({ ... });
const UpdateResourceSchema = CreateResourceSchema.partial();
const ResourceParamsSchema = z.object({ id: z.string().uuid() });
```

**Python** — Pydantic models:
```python
class CreateResource(BaseModel): ...
class UpdateResource(BaseModel): ...
class ResourceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
```

**C#** — FluentValidation or Data Annotations:
```csharp
public record CreateResourceRequest(string Name, ...);
public class CreateResourceValidator : AbstractValidator<CreateResourceRequest> { ... }
```

## Step 4 — Create the API routes/controllers

Implement standard CRUD endpoints:

| Method | Path | Status | Description |
|--------|------|--------|-------------|
| `GET` | `/api/v1/<resources>` | 200 | List with pagination |
| `GET` | `/api/v1/<resources>/:id` | 200 / 404 | Get by ID |
| `POST` | `/api/v1/<resources>` | 201 | Create |
| `PUT` | `/api/v1/<resources>/:id` | 200 / 404 | Full update |
| `PATCH` | `/api/v1/<resources>/:id` | 200 / 404 | Partial update |
| `DELETE` | `/api/v1/<resources>/:id` | 204 / 404 | Delete |

**Rules:**
- List endpoint must support pagination (`?page=1&limit=20`, default limit ≤ 20).
- List endpoint must support filtering by common fields.
- List endpoint must support sorting (`?sort=created_at&order=desc`).
- All endpoints validate input before processing.
- All endpoints return structured error responses on failure.
- Resource-level authorization: users can only access resources they own (unless admin).

## Step 5 — Create the service/business logic layer

Separate route handlers from business logic:

```
routes/   (or controllers/)  → HTTP concerns (parse, validate, respond)
services/                    → Business logic (rules, orchestration)
repositories/                → Data access (queries, mutations)
```

**Rules:**
- Services never import HTTP framework types.
- Repositories never contain business rules.
- Use dependency injection — no global singletons or service locators.

## Step 6 — Write tests

**Unit tests** (service layer — mock the repository):
- Create: valid input → resource created
- Create: invalid/duplicate input → appropriate error
- Get: existing ID → resource returned
- Get: non-existent ID → not-found error
- Update: valid changes → resource updated
- Delete: existing ID → resource deleted / soft-deleted
- List: pagination, filtering, sorting behaviour

**Integration tests** (API layer — real database via Testcontainers):
- Full request/response cycle for each endpoint
- Auth enforcement (unauthenticated → 401, unauthorized → 403)
- Validation errors return 422 with structured body

## Step 7 — Commit the scaffold

```bash
git add -A
git commit -m "feat(<resource>): scaffold CRUD API with tests

- Model, migration, validation, routes, service, repository
- Unit and integration tests
- Pagination, filtering, sorting on list endpoint

Closes #<issue-number>"
```
