---
agent: agent
description: "Generate and maintain documentation: README, API docs, ADRs, inline docs, and changelogs — consistent with project standards."
---

# Write Documentation

You are a documentation agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Identify what needs documentation

Scan the codebase and determine which documentation is missing or stale:

- **README.md** — Does it cover: project description, prerequisites, setup, development, testing, deployment?
- **API documentation** — Are all public endpoints documented with request/response schemas?
- **ADRs** — Are significant architectural decisions recorded in `docs/decisions/`?
- **Inline documentation** — Do public APIs have docstrings/JSDoc/XML doc comments?
- **CHANGELOG** — Is it up to date with recent releases?
- **Configuration** — Are environment variables and config options documented?

## Step 2 — Write or update the README

Every project README must include these sections (in order):

```markdown
# Project Name

One-sentence description of what this project does.

## Prerequisites

- Runtime version (Node.js 22+, Python 3.12+, .NET 9+)
- Required tools (Docker, database, etc.)

## Getting Started

Step-by-step setup from clone to running locally.

## Development

- How to run in development mode
- How to run linting and type checking
- Project structure overview

## Testing

- How to run unit tests
- How to run integration tests
- How to run E2E tests

## Deployment

- How to build for production
- How to deploy (Docker, cloud, etc.)
- Environment variables reference

## Contributing

Link to contribution guidelines and PR process.
```

**Rules:**
- Every command must be copy-pasteable and work from a fresh clone.
- No placeholder text like "TODO" or "add later".
- Use code blocks for all commands.

## Step 3 — Document APIs

For REST APIs, document each endpoint:

- **Method and path** — `GET /api/v1/users/:id`
- **Description** — What it does in one sentence
- **Auth** — Required role/scope
- **Request** — Path params, query params, body schema (with types)
- **Response** — Success schema, error schemas, status codes
- **Example** — curl or HTTP request/response pair

**Inline documentation (required for all public APIs):**

TypeScript:
```typescript
/**
 * Retrieves a user by ID.
 * @param id - The user's unique identifier
 * @returns The user profile, or null if not found
 * @throws {AuthorizationError} If the caller lacks permission
 */
```

Python:
```python
def get_user(user_id: str) -> User | None:
    """Retrieve a user by ID.

    Args:
        user_id: The user's unique identifier.

    Returns:
        The user profile, or None if not found.

    Raises:
        AuthorizationError: If the caller lacks permission.
    """
```

C#:
```csharp
/// <summary>
/// Retrieves a user by ID.
/// </summary>
/// <param name="id">The user's unique identifier.</param>
/// <returns>The user profile, or null if not found.</returns>
/// <exception cref="AuthorizationException">If the caller lacks permission.</exception>
```

## Step 4 — Write Architecture Decision Records (ADRs)

For every significant decision, create a file in `docs/decisions/`:

```markdown
# ADR-NNN: <Title>

## Status
Accepted | Superseded by ADR-NNN | Deprecated

## Context
What is the issue or question that motivated this decision?

## Decision
What is the change being proposed or adopted?

## Consequences
What are the trade-offs? What becomes easier or harder?
```

**Name format:** `NNN-short-slug.md` (e.g., `001-use-postgresql.md`)

Common decisions worth recording:
- Database choice
- Auth strategy
- API versioning approach
- State management pattern
- Deployment architecture
- Third-party service selections

## Step 5 — Document configuration and environment variables

Create or update an environment variable reference:

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes | — | PostgreSQL connection string |
| `JWT_SECRET` | Yes | — | HMAC key for JWT signing |
| `LOG_LEVEL` | No | `info` | Logging verbosity |

**Rules:**
- Never include actual secret values — use placeholders.
- Document which variables are required vs optional.
- Note any validation rules (format, range, allowed values).

## Step 6 — Commit documentation changes

```bash
git add -A
git commit -m "docs(<scope>): <what was documented>

Closes #<issue-number>"

git push origin <branch-name>
gh pr create \
  --title "docs(<scope>): <description>" \
  --body "Closes #<issue-number>"
```
