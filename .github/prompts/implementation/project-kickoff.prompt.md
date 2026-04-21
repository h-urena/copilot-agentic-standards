---
agent: agent
description: "Bootstrap a new project from scratch: scaffold the repo structure, configure tooling, wire CI, and fill in project memory — all following agentic standards."
---

# Project Kickoff

You are a project bootstrap agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Gather project context

Before creating any file, answer these questions (ask the user if any are unclear):

- **Project name** and short description
- **Primary stack(s):** TypeScript, Python, C#, or a combination
- **Project type:** API, web app, CLI tool, library, monorepo, microservices
- **Auth strategy:** OAuth 2.0 / JWT / session-based / none (for internal tools)
- **Database:** PostgreSQL, SQL Server, MongoDB, SQLite, none
- **Deployment target:** Docker / Kubernetes / serverless / bare metal
- **External integrations:** Payment providers, third-party APIs, message queues

Record answers in `.github/project-context.md` immediately.

## Step 2 — Scaffold the repository structure

Create the directory layout appropriate for the stack and project type.

**Monorepo (multi-stack)**
```
apps/
  <service-name>/        # Each deployable unit
    src/
    tests/
    Dockerfile
packages/                # Shared libraries (if applicable)
docs/
  decisions/             # ADRs
docker-compose.yml
.github/
  workflows/
  prompts/
```

**Single-stack API**
```
src/
  <module>/
tests/
  unit/
  integration/
  e2e/
docs/
  decisions/
Dockerfile
.github/
  workflows/
  prompts/
```

**Rules:**
- Every deployable unit gets its own `Dockerfile`.
- Every project gets a `docs/decisions/` folder for ADRs.
- Test directories mirror source structure.

## Step 3 — Configure stack tooling

**TypeScript**
- `package.json` with `scripts`: `dev`, `build`, `test`, `lint`, `typecheck`
- `tsconfig.json` with `strict: true`, `moduleResolution: "bundler"` or `"NodeNext"`
- ESLint + Prettier configs
- Vitest config

**Python**
- `pyproject.toml` as single source of truth (PEP 621)
- Ruff config (`[tool.ruff]` in pyproject.toml)
- mypy config (`[tool.mypy]` in pyproject.toml with `strict = true`)
- pytest config (`[tool.pytest.ini_options]`)
- Virtual environment via `uv` or `poetry`

**C#**
- `.sln` file at root
- `Directory.Build.props` with `<Nullable>enable</Nullable>`, `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`
- `.editorconfig` with C# style rules
- xUnit test project(s)

**All stacks**
- `.editorconfig` at repo root
- `.gitignore` appropriate for the stack
- `README.md` with: project description, prerequisites, setup, development, testing, deployment

## Step 4 — Wire CI pipeline

Create `.github/workflows/ci.yml` with:

1. **Lint** — run stack linter (ESLint / Ruff / `dotnet build -warnaserror`)
2. **Type-check** — `tsc --noEmit` / `mypy --strict` / build step
3. **Unit tests** — fast, no external deps
4. **Integration tests** — Testcontainers for real infra
5. **Build** — produce artifact (Docker image / dist / publish-ready package)

Use the reusable workflows from copilot-agentic-standards where applicable:

```yaml
jobs:
  merge-rules:
    uses: h-urena/copilot-agentic-standards/.github/workflows/merge-rules.yml@main
    permissions:
      contents: read
      pull-requests: read
  pr-description:
    uses: h-urena/copilot-agentic-standards/.github/workflows/pr-description.yml@main
    permissions:
      pull-requests: write
```

## Step 5 — Configure containerization

For every deployable unit, create:

- `Dockerfile` — multi-stage build, non-root user, health check
- `docker-compose.yml` (development) — app + dependencies (DB, cache, queue)
- `.dockerignore` — exclude `node_modules`, `.git`, test artifacts, secrets

See the Docker templates in this repo for stack-specific examples.

## Step 6 — Fill in project memory and documentation

- Complete `.github/project-context.md` with all gathered context
- Create initial ADR: `docs/decisions/001-initial-architecture.md`
- Write `README.md` with setup instructions
- Ensure `.github/copilot-instructions.md` is present (from onboarding)

## Step 7 — Commit and open the initial PR

```bash
git add -A
git commit -m "feat: scaffold project structure and tooling

- <stack> project with <key tooling choices>
- CI pipeline with lint, test, build stages
- Docker configuration for development and deployment
- Project memory and documentation bootstrapped

Closes #<issue-number>"

git push origin <branch-name>
gh pr create \
  --title "feat: scaffold project structure and tooling" \
  --body "Closes #<issue-number>"
```
