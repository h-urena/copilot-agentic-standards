---
agent: agent
description: "Scaffold a multi-service monorepo: directory layout, shared tooling, inter-service contracts, per-service CI."
---

# Scaffold Monorepo

**Constraint:** Do not write any files until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
Services:    [name: responsibility: stack for each service]
Shared code: [Yes: types | clients | utilities | None]
Package mgr: [npm workspaces | pnpm workspaces | uv workspaces | NuGet local projects]
Deployment:  [Independent per service | Composed together]
</schema>

## 1. DIRECTORY_STRUCTURE

```
monorepo-root/
├── apps/
│   └── <service>/          # One directory per deployable service
├── packages/               # Shared code (TypeScript only)
│   ├── types/              # Shared types / contracts
│   └── config/             # Shared ESLint / TS config
├── infra/                  # IaC (Terraform / Bicep / Pulumi)
├── scripts/
│   ├── setup.sh            # One-command dev bootstrap
│   └── check-all.sh        # Lint + test across all services
├── docs/decisions/         # ADRs
├── docker-compose.yml      # All services for local dev
└── README.md
```

## 2. WORKSPACE_TABLE

| Stack | Config file | Key constraint |
|---|---|---|
| TypeScript (pnpm) | `pnpm-workspace.yaml` | Each app is a workspace package |
| Python (uv) | `pyproject.toml` `[tool.uv.workspace]` | `members = ["apps/*"]` |
| C# | `.sln` + `dotnet sln add` | All projects in solution |

## 3. SHARED_CONTRACT_RULES

| Rule | Constraint |
|---|---|
| Single source of truth | Types defined once in `packages/types/` — never duplicated |
| No database sharing | Each service owns its database |
| Contract-first | API contracts (OpenAPI / Protobuf / Avro) defined before implementation |

## 4. CI_REQUIREMENTS

| Check | Constraint |
|---|---|
| Path filtering | Each service CI triggers only when its files change |
| Shared package changes | Triggers CI for all consuming services |
| Root scripts | `check-all.sh` runs lint + test across all services |
| Per-service Dockerfile | Every deployable unit has its own `Dockerfile` |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Shared database between services | Coupling; deployment dependency |
| Type duplication across services | Divergence; maintenance burden |
| Single CI job for all services | Unrelated failures block unrelated services |
| Big-bang migration to monorepo | Migrate service-by-service |
| Floating dependency versions | Breaks workspace reproducibility |