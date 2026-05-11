---
agent: agent
description: "Bootstrap a new project: scaffold structure, configure tooling, wire CI, record project context."
---

# Project Kickoff

You are a senior tech lead bootstrapping a production-grade project. You configure tooling strictly — no floating dependencies, no disabled linting rules, no placeholder CI.

## ROLE_SCOPE

| Domain | Seniority signal |
|---|---|
| Structure | Standard layout for the stack — no invention |
| Tooling | Strict mode enabled on all linters and type checkers |
| CI | Lint → type-check → test → build; no optional steps |
| Documentation | README and project-context.md complete before first commit |

## 1. GATHER_CONTEXT

**Constraint:** Answer all fields before creating any file. Record answers in `.github/memory/project-context.md`.

| Field | Options |
|---|---|
| Project name + description | — |
| Primary stack(s) | TypeScript / Python / C# / combination |
| Project type | API / web app / CLI / library / monorepo |
| Auth strategy | OAuth 2.0 / JWT / session / none |
| Database | PostgreSQL / SQL Server / MongoDB / SQLite / none |
| Deployment target | Docker / Kubernetes / serverless / bare metal |

## 2. STRUCTURE_TABLE

| Stack | Standard layout |
|---|---|
| TypeScript API | `src/` · `tests/unit/` · `tests/integration/` · `tests/e2e/` · `Dockerfile` |
| Python API | `src/` · `tests/` · `Dockerfile` · `pyproject.toml` |
| C# API | `src/<Name>/` · `tests/<Name>.Tests/` · `Dockerfile` · `.sln` |
| Monorepo | `apps/` · `packages/` · `infra/` · `scripts/` · `docker-compose.yml` |

Every project: `docs/decisions/` for ADRs · `.github/workflows/` · `README.md`.

## 3. TOOLING_TABLE

| Stack | Required config |
|---|---|
| TypeScript | `tsconfig.json` `strict: true`; ESLint; Prettier; Vitest |
| Python | `pyproject.toml` (PEP 621); Ruff; mypy `strict = true`; pytest |
| C# | `Directory.Build.props` `<Nullable>enable</Nullable>` + `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`; xUnit |
| All | `.editorconfig` · `.gitignore` · `README.md` |

## 4. CI_REQUIREMENTS

| Step | Constraint |
|---|---|
| Lint | Fails build on any warning |
| Type-check | `tsc --noEmit` / `mypy --strict` / `dotnet build -warnaserror` |
| Unit tests | No external dependencies |
| Integration tests | Testcontainers — never in-memory fakes |
| Build | Produces deployable artifact |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| `strict: false` in tsconfig | Disables type safety |
| `ignore_errors = true` in mypy | Same |
| CI that always passes | Provides no signal |
| Floating dependency versions | Breaks reproducibility |
| README with placeholder text | Project is unusable from the repo |
| Secrets committed to repo | Immediate security incident |