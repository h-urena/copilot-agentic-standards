---
agent: agent
description: "Scaffold a multi-service monorepo: directory layout, shared tooling, inter-service contracts, CI per service."
---

# Scaffold Monorepo

You are a monorepo scaffolding agent. Work through the steps below in order.

## Step 1 — Confirm requirements

Before writing any files, confirm:

- **Services:** What are the names and responsibilities of each service?
- **Stacks:** Which stack does each service use? (TypeScript / Python / C# / mixed)
- **Shared code:** Is there shared code between services? (types, clients, utilities)
- **Package manager workspace support:** npm / pnpm / uv workspaces / NuGet local projects?
- **Deployment target:** Each service deployed independently? Or composed together?

## Step 2 — Directory layout

```
monorepo-root/
├── apps/
│   ├── api/                  # Backend service (TypeScript/Python/C#)
│   ├── web/                  # Frontend (TypeScript)
│   ├── worker/               # Background job processor
│   └── <service-n>/
├── packages/                 # Shared code (TypeScript monorepo only)
│   ├── types/                # Shared TypeScript types / Pydantic models / C# contracts
│   ├── ui/                   # Shared UI component library (if applicable)
│   └── config/               # Shared ESLint, TS config, etc.
├── infra/                    # Infrastructure as code (Terraform, Bicep, Pulumi)
├── scripts/
│   ├── setup.sh              # One-command dev bootstrap
│   └── check-all.sh          # Run lint + test across all services
├── docs/
│   └── decisions/            # ADRs
├── .github/
│   └── workflows/            # Per-service CI + monorepo orchestration
├── docker-compose.yml        # All services for local development
└── README.md
```

## Step 3 — Workspace configuration

**TypeScript (pnpm workspaces — preferred for monorepos)**
```yaml
# pnpm-workspace.yaml
packages:
  - 'apps/*'
  - 'packages/*'
```

```json
// Root package.json
{
  "name": "monorepo-root",
  "private": true,
  "scripts": {
    "build": "pnpm -r build",
    "test": "pnpm -r test",
    "lint": "pnpm -r lint",
    "typecheck": "pnpm -r typecheck"
  }
}
```

**Python (uv workspaces)**
```toml
# pyproject.toml (root)
[tool.uv.workspace]
members = ["apps/*"]
```

**C# (solution file)**
```bash
dotnet new sln -n MonorepoName
dotnet sln add apps/Api/Api.csproj
dotnet sln add apps/Worker/Worker.csproj
```

## Step 4 — Shared types / contracts package

Cross-service types must be defined once and consumed by all services. Never duplicate a type across services.

**TypeScript**
```typescript
// packages/types/src/index.ts
export interface User {
  id: string;
  email: string;
  createdAt: Date;
}
```

**Python (shared Pydantic models)**
```python
# packages/types/models.py
from pydantic import BaseModel

class User(BaseModel):
    id: str
    email: str
    created_at: datetime
```

## Step 5 — CI configuration

Create a CI workflow per service that triggers on path changes only:

```yaml
# .github/workflows/ci-api.yml
name: CI — api
on:
  push:
    paths:
      - 'apps/api/**'
      - 'packages/**'
      - '.github/workflows/ci-api.yml'
  pull_request:
    paths:
      - 'apps/api/**'
      - 'packages/**'
      - '.github/workflows/ci-api.yml'

jobs:
  ci:
    uses: ./.github/workflows/reusable-ci.yml
    with:
      service: api
      working-directory: apps/api
```

Also create a `ci-all.yml` that triggers on changes to root config files and runs all services.

## Step 6 — Docker Compose for local development

```yaml
# docker-compose.yml
services:
  api:
    build: apps/api
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/app
    depends_on:
      db:
        condition: service_healthy

  worker:
    build: apps/worker
    environment:
      DATABASE_URL: postgresql://postgres:postgres@db:5432/app
      REDIS_URL: redis://redis:6379
    depends_on:
      - db
      - redis

  web:
    build: apps/web
    ports: ["5173:5173"]

  db:
    image: postgres:17-alpine
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-appuser}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD is required}
      POSTGRES_DB: ${POSTGRES_DB:-app}
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-appuser}"]
      interval: 5s
      timeout: 3s
      retries: 5
    volumes:
      - db-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]

volumes:
  db-data:
```

## Step 7 — Bootstrap script

```bash
#!/usr/bin/env bash
# scripts/setup.sh
set -euo pipefail

echo "Installing dependencies..."
pnpm install  # or: uv sync / dotnet restore

echo "Setting up environment files..."
for service in apps/*/; do
  if [[ -f "$service.env.example" && ! -f "$service.env" ]]; then
    cp "$service.env.example" "$service.env"
    echo "Created $service.env from .env.example — fill in secrets"
  fi
done

echo "Starting infrastructure services..."
docker compose up -d db redis

echo "Running database migrations..."
# pnpm --filter api exec prisma migrate dev
# or: uv run --project apps/api alembic upgrade head

echo "Setup complete. Run: docker compose up"
```

## Step 8 — README

Create a root `README.md` that documents:
- Project overview and service map
- Prerequisites (Node/Python/dotnet version, Docker)
- Quick start: `./scripts/setup.sh && docker compose up`
- Service descriptions and ports
- How to add a new service
- Link to `docs/decisions/` for architecture decisions
