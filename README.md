# copilot-agentic-standards

Single source of truth for Copilot instructions, reusable workflows, PR templates, agent prompts,
persona skills, and MCP configs — so every repo on the team starts (and stays) consistent,
regardless of whether it is TypeScript, Python, C#, or a combination.

## Why

Without a shared baseline, repositories drift: different branch strategies, inconsistent PR titles,
missing squash policies, ad-hoc Copilot instructions, and agents that behave differently across
projects. This repo fixes that with **composable, stack-aware standards** that any project can
adopt with a single bootstrap script.

---

## For teams adopting the standards

### Quick start — green field (new project)

Use this path when creating a brand-new repository from scratch.

**Step 1 — Choose a stack**

| Stack | Use when |
| ----- | -------- |
| `typescript` | Node.js APIs, full-stack apps, CLIs, or any JS/TS project |
| `python` | Data pipelines, ML workloads, Django/FastAPI services |
| `csharp` | .NET APIs, background services, or any C# project |
| `typescript+python` | Projects with a TypeScript frontend and a Python backend |

**Step 2 — Run the bootstrap script with `--create`**

```bash
git clone https://github.com/h-urena/copilot-agentic-standards.git
./copilot-agentic-standards/scripts/onboard-repo.sh \
  --repo ../my-new-project \
  --stack typescript \
  --create
```

The `--create` flag creates the GitHub repository, clones it locally, copies all standards files
into it, creates conventional-commit labels, and provisions a GitHub Project board.

**Step 3 — Complete post-setup (once, by the repo owner)**

After the script finishes, do these steps once:

1. **Enable branch protection on `main`** — follow the `gh api` commands printed by the script
   at the end of its run.
2. **Fill in `.github/project-context.md`** — open it and answer the prompted sections so agents
   have project context without re-exploring the codebase every session.
3. **Verify CI is green** — open the repo on GitHub and confirm the initial workflow runs pass.
4. **Pin `pull-standards.yml`** — it was already copied; confirm it is enabled under
   Settings → Actions → Workflows.

---

### Quick start — brown field (existing repo)

Use this path when applying the standards to a repo that already exists.

**Step 1 — Run the bootstrap script (no `--create` flag)**

```bash
# Remotely (no clone needed)
curl -sL https://raw.githubusercontent.com/h-urena/copilot-agentic-standards/main/scripts/onboard-repo.sh \
  | bash -s -- --stack typescript

# Or clone locally first
git clone https://github.com/h-urena/copilot-agentic-standards.git
./copilot-agentic-standards/scripts/onboard-repo.sh --repo ../my-project --stack python
```

The script is idempotent — it skips files that already exist. Pass `--force` to overwrite
existing files (use with care if you have customized them).

**Step 2 — Review what was added**

```bash
cd ../my-project
git status   # review the new/modified files before committing
```

Key files to inspect: `.github/copilot-instructions.md`, `.vscode/mcp.json`,
`.github/workflows/pull-standards.yml`.

**Step 3 — Complete post-setup (once, by the repo owner)**

1. **Enable branch protection on `main`** — run the `gh api` commands printed by the script.
2. **Fill in `.github/project-context.md`** — open it and fill in the project-specific sections.
3. **Commit and push the bootstrapped files** — open a PR following the governance workflow
   (`.github/prompts/governance.prompt.md`).
4. **Verify CI is green** — confirm `pull-standards.yml` and any other new workflows pass.

The script copies everything listed in the table below. Run it once; after that,
`pull-standards.yml` keeps the repo in sync automatically.

### What gets copied by `onboard-repo.sh`

| File / folder | Destination | Purpose |
| ------------- | ----------- | ------- |
| `composed/<stack>-copilot-instructions.md` | `.github/copilot-instructions.md` | Universal + stack-specific Copilot rules |
| `instructions/code-review.instructions.md` | `.github/` | Generic code review checklist |
| `instructions/code-review-<stack>.instructions.md` | `.github/` | Stack-specific review checklist |
| `instructions/*.instructions.md` | `.github/` | Domain instruction files (API design, auth, DB patterns) |
| `templates/pull-request/` | `.github/PULL_REQUEST_TEMPLATE/` | Default and hotfix PR templates |
| `workflows/sync/pull-standards.yml` | `.github/workflows/` | Keeps standards in sync weekly |
| `composed/<stack>.mcp.json` | `.vscode/mcp.json` | MCP server config for Copilot tools |
| `.github/prompts/implementation/` | `.github/prompts/implementation/` | Implementation prompts (governance, feature, bug, refactor, kickoff, tests, docs) |
| `.github/prompts/review/` | `.github/prompts/review/` | Review and audit prompts |
| `.github/prompts/scaffolds/` | `.github/prompts/scaffolds/` | Scaffold prompts (CRUD, auth, DB, frontend) |
| `.github/prompts/personas/` | `.github/prompts/personas/` | Persona prompts (DevOps, Principal, QA) |
| `.github/CODEOWNERS` | `.github/CODEOWNERS` | Auto-generated from git remote owner |
| `templates/dependabot.<stack>.yml` | `.github/dependabot.yml` | Stack-appropriate Dependabot config |
| `templates/vscode/extensions.<stack>.json` | `.vscode/extensions.json` | Recommended VS Code extensions |
| `templates/memory/project-context.md` | `.github/project-context.md` | Agent memory bootstrap template |
| `templates/.editorconfig` | `.editorconfig` | Consistent formatting across editors |
| `templates/labeler.yml` | `.github/labeler.yml` | Path-based PR labeling config |
| `templates/docker/Dockerfile.<stack>` | `Dockerfile` | Multi-stage Docker build template |
| `templates/docker/.dockerignore` | `.dockerignore` | Docker build exclusions |
| `templates/docker/docker-compose.yml` | `docker-compose.yml` | Local development environment |
| `templates/ci/ci.<stack>.yml` | `.github/workflows/ci.yml` | Stack-specific CI pipeline |
| `skills/*.skill.md` | `.github/skills/` | Copilot Skill files (test generation, code analysis, etc.) |

### Multi-stack projects

For projects combining stacks (e.g., TypeScript frontend + Python API), use the `+` separator:

```bash
./scripts/compose.sh typescript+python
./scripts/onboard-repo.sh --repo ../my-project --stack typescript+python
```

This produces:

- `composed/python+typescript-copilot-instructions.md` — base + both stack instructions
- `composed/python+typescript.mcp.json` — merged MCP config from all stacks
- Code review checklists for all included stacks

### Keep standards in sync

`pull-standards.yml` runs every Monday at 09:00 UTC and opens a PR on the downstream repo when
anything in this standards repo changes. Running `onboard-repo.sh` installs it automatically.

**What it updates on each run:**

- `.github/copilot-instructions.md` — from the latest composed file for the repo's stack
- All domain instruction files (`api-design`, `auth-patterns`, `db-patterns`, etc.)
- Code review checklists (generic + stack-specific)
- All prompt files under `.github/prompts/`
- Skill files under `.github/skills/`
- PR description and merge-rules reusable workflows
- Runtime version pins in `ci.yml` and `Dockerfile` (Python, Node.js, .NET) from `versions.json`

**How to apply latest changes manually**

1. Go to your repo on GitHub → Actions → `pull-standards` workflow.
2. Click **Run workflow** → **Run workflow** (no inputs needed).
3. The workflow opens a PR titled `chore: update standards from h-urena/copilot-agentic-standards`.
4. Review the diff in that PR — it shows exactly which files changed.
5. Merge the PR. Standards are now up to date.

**Stack detection**

The workflow reads the first five lines of `.github/copilot-instructions.md` for a comment like
`<!-- Stack: typescript -->`. This comment is written by `onboard-repo.sh`. Do not remove or
move it, or the sync workflow will silently skip updating the main instructions file.

**If you don't yet have the workflow**

```bash
cp workflows/sync/pull-standards.yml ../my-project/.github/workflows/pull-standards.yml
```

### Agent prompts

All prompts in `.github/prompts/` are distributed to downstream repos and invocable from VS Code
Copilot Chat with `#<prompt-name>` or via the Copilot agent mode. Prompts are organized into four
subfolders: `implementation/`, `review/`, `scaffolds/`, and `personas/`.

**Governance prompt** (`.github/prompts/`)
| Prompt | Purpose |
| ------ | ------- |
| `governance.prompt.md` | Full governance workflow — run before any change (issue → branch → PR) |

**Implementation prompts** (`.github/prompts/implementation/`)

| Prompt | Purpose |
| ------ | ------- |
| `governance.prompt.md` | Full governance workflow — run before any change (issue → branch → PR) |
| `feature.prompt.md` | End-to-end feature implementation: design, code, tests, PR |
| `bug.prompt.md` | Systematic bug fix: reproduce → root cause → targeted fix → regression test |
| `test.prompt.md` | Write comprehensive test suites for existing code |
| `kickoff.prompt.md` | Bootstrap a new project: scaffold structure, tooling, CI, Docker |
| `refactor.prompt.md` | Systematic refactoring: preserve behavior, incremental changes, no regressions |
| `docs.prompt.md` | Generate/update documentation: README, API docs, ADRs, changelogs |
| `adr.prompt.md` | Record an Architecture Decision: context, options, decision, consequences |
| `deploy.prompt.md` | Deploy a service: pre-deploy checks, migrations, health checks, rollback |

**Review prompts** (`.github/prompts/review/`)

| Prompt | Purpose |
| ------ | ------- |
| `audit.prompt.md` | Standards audit: validate a branch diff against all project rules |
| `security-audit.prompt.md` | OWASP-focused security audit: secrets, auth, injection, dependencies |
| `performance-audit.prompt.md` | Performance audit: N+1 queries, missing indexes, caching, bundle size |
| `dependency-audit.prompt.md` | Dependency audit: CVEs, outdated packages, license compliance, supply chain |

**Scaffold prompts** (`.github/prompts/scaffolds/`)

| Prompt | Purpose |
| ------ | ------- |
| `crud-api.prompt.md` | Scaffold a CRUD API: routes, models, validation, service layer, tests |
| `auth.prompt.md` | Wire auth: identity provider, middleware, route protection, audit logging |
| `database.prompt.md` | Set up database: connection, ORM, migrations, seeding, health check |
| `frontend.prompt.md` | Scaffold frontend component: structure, a11y, state, forms, tests |
| `background-jobs.prompt.md` | Scaffold async worker: queue, job definition, retry, dead-letter, monitoring |
| `notifications.prompt.md` | Scaffold notifications: email, webhooks, push, retry, opt-out, preferences |
| `monorepo.prompt.md` | Scaffold multi-service monorepo: layout, workspaces, contracts, CI per service |

**Persona prompts** (`.github/prompts/personas/`)

| Prompt | Purpose |
| ------ | ------- |
| `persona-devops-engineer.prompt.md` | Adopt a DevOps Engineer perspective for infra, CI/CD, and deployment review |
| `persona-principal-engineer.prompt.md` | Adopt a Principal Engineer perspective for architecture and design review |
| `persona-qa-engineer.prompt.md` | Adopt a Senior QA Engineer perspective for coverage and quality risk review |
| `architect.prompt.md` | Adopt a Principal Architect perspective: system design, service decomposition, ADRs |
| `product-manager.prompt.md` | Adopt a Product Manager perspective: PRDs, user stories, acceptance criteria |

### Copilot Skill files — `skills/`

Skill files give agents specialized domain knowledge for tasks like test generation, code analysis,
API design review, performance profiling, and data migration. They live at the repo root in `skills/`
because they are **complete, ready-to-use operational files** — agents load them directly, you
never fill them in. They are distributed to downstream repos as `.github/skills/`.

| Skill file | Purpose |
| ---------- | ------- |
| `test-generation.skill.md` | Write comprehensive test suites: AAA, mocks, coverage plan, Testcontainers |
| `code-analysis.skill.md` | Five-phase deep code analysis: correctness, security, performance, maintainability |
| `api-design-review.skill.md` | API contract review: URL design, status codes, security, rate limiting |
| `performance-profiling.skill.md` | Performance analysis: N+1, indexes, caching, async I/O, bundle size |
| `data-migration.skill.md` | Safe schema migrations: Expand/Backfill/Contract, risk classification, verification |

### Agent memory — `project-context.md`

Copy `templates/memory/project-context.md` to `.github/project-context.md` in your repo and fill
it in during project kickoff. Agents read this file to understand the project without re-exploring
the codebase each session.

Use the **MCP memory server** (included in `mcp/base.mcp.json`) for in-session working memory.
Use `project-context.md` for long-lived facts that survive between sessions.

### Supported stacks

| Stack | Instruction file | Code review checklist | MCP config |
| ----- | --------------- | -------------------- | ---------- |
| TypeScript | `instructions/stacks/typescript.md` | `instructions/code-review-typescript.instructions.md` | `mcp/typescript.mcp.json` |
| Python | `instructions/stacks/python.md` | `instructions/code-review-python.instructions.md` | `mcp/python.mcp.json` |
| C# | `instructions/stacks/csharp.md` | `instructions/code-review-csharp.instructions.md` | `mcp/csharp.mcp.json` |

---

## For maintainers of this repo

> Before making any change, follow the full governance workflow in
> `.github/prompts/implementation/governance.prompt.md`. Never push directly to `main`.

### Repo structure

```text
instructions/          Copilot instruction files (base + per-stack)
  base.md              Universal rules — inherited by all stacks
  stacks/              Additive per-stack rules (typescript, python, csharp)
  *.instructions.md    Domain files: API design, auth patterns, DB patterns, code review
composed/              Auto-generated by scripts/compose.sh — never edit directly
.github/
  workflows/           Active GitHub Actions (pr-description, code-review, merge-rules, …)
  prompts/
    implementation/    Implementation prompts (governance, implement-feature, fix-bug, …)
    review/            Review and audit prompts (audit, security-audit)
    scaffolds/         Scaffold prompts (crud-api, auth, database, frontend)
    personas/          Persona prompts (DevOps, Principal Engineer, QA)
workflows/
  reusable/            Documentation-only mirrors of .github/workflows/ reusable files
  examples/            Example caller workflow for consumer repos
  sync/                Workflow consumers run to pull updates from this repo
templates/
  pull-request/        PR templates (default, hotfix) — fill in per project
  memory/              project-context.md — fill in during kickoff
  vscode/              Stack-specific extensions.json — starting-point, customize as needed
  docker/              Docker files, .dockerignore, docker-compose.yml — starting-point
  ci/                  CI pipeline templates (ci, release, stale) — starting-point
  labeler.yml          Path-based PR labeling config
  .editorconfig        Consistent editor formatting rules
skills/                Copilot Skill files — operational, used as-is by agents
mcp/                   MCP server configs (base + per-stack)
scripts/               compose.sh, validate-composed.sh, onboard-repo.sh
```

### Local development setup

**Prerequisites** (install once globally, skip if already present):

| Tool | Required for | Install |
| ---- | ------------ | ------- |
| `bash` (≥4) | `onboard-repo.sh` | macOS: `brew install bash`; Linux: built-in; Windows: Git Bash or WSL |
| `gh` CLI | `onboard-repo.sh` — creating repos, labels, project boards | <https://cli.github.com> |
| `jq` | `onboard-repo.sh` — merging MCP configs on-the-fly (optional; falls back gracefully) | `brew install jq` / `apt install jq` |
| `GH_PROJECT_PAT` | `onboard-repo.sh` — auto-creating GitHub Project boards | Classic PAT with `project` scope (fine-grained PATs not supported) |
| Python + `pre-commit` | YAML lint hook at commit time | `pip install pre-commit` |

**Step 1 — Install the pre-commit framework (global, skip if already installed):**

```bash
pip install pre-commit
```

**Step 2 — Register the hooks for this repo (required once per clone):**

```bash
pre-commit install
```

After that, every `git commit` automatically lints staged `*.yml`/`*.yaml` files with yamllint
(max 130 chars/line).

> **Ad-hoc:** To lint all files without committing (e.g. before raising a PR):
>
> ```bash
> pre-commit run --all-files
> ```

### Composing instruction files

`scripts/compose.sh` merges `instructions/base.md` with a stack file into a single ready-to-use
file in `composed/`.

```bash
./scripts/compose.sh typescript          # → composed/typescript-copilot-instructions.md
./scripts/compose.sh python              # → composed/python-copilot-instructions.md
./scripts/compose.sh csharp             # → composed/csharp-copilot-instructions.md
./scripts/compose.sh typescript+python  # → composed/python+typescript-copilot-instructions.md
./scripts/compose.sh all                 # → all individual stack composed files
```

CI runs `scripts/validate-composed.sh` on every PR to ensure composed files are never stale.

### Adding a new stack

1. Create `instructions/stacks/<stack>.md`
2. Create `mcp/<stack>.mcp.json`
3. Create `instructions/code-review-<stack>.instructions.md`
4. Update `scripts/compose.sh` to include the new stack
5. Run `./scripts/compose.sh all` and commit the result

### Workflows

| Workflow | Location | Type | Purpose |
| -------- | -------- | ---- | ------- |
| `pr-description.yml` | `.github/workflows/` | Reusable | Auto-fills PR body from commit messages on open/sync |
| `code-review.yml` | `.github/workflows/` | Reusable | Tiered automated code review (critical + suggestions) |
| `auto-fix.yml` | `.github/workflows/` | Reusable | Auto-fixes bot REQUEST_CHANGES reviews; posts agent-ready checklist for code issues |
| `merge-rules.yml` | `.github/workflows/` | Reusable | Squash enforcement, commitlint, branch naming |
| `pr-automation.yml` | `.github/workflows/` | Reusable | Auto-assign, label, welcome comment |
| `project-automation.yml` | `.github/workflows/` | Internal | GitHub Project board lifecycle automation |
| `validate.yml` | `.github/workflows/` | Internal | CI — validates composed files are not stale |
| `example-ci.yml` | `workflows/examples/` | Example | Shows how a consumer repo calls reusable workflows |
| `pull-standards.yml` | `workflows/sync/` | Sync | Consumer-side weekly sync — updates instructions, prompts, skills, and reusable workflows |

### PR description auto-generation

`pr-description.yml` runs on every `pull_request` (opened / synchronize / reopened). It:

1. Reads all commits on the branch and parses them as Conventional Commits.
2. Groups them by type (feat, fix, docs, …) and fills in the PR body template automatically.
3. Pre-checks the "Type of change" checkboxes based on commit types found.
4. Extracts the issue number from the branch name (`feat/42-slug` → `Closes #42`).
5. **Never overwrites a manually edited description.** A description is considered manual when the
   `<!-- pr-description: auto -->` HTML comment has been removed.

Consumer repos call it as:

```yaml
permissions:
  pull-requests: write
jobs:
  pr-description:
    uses: h-urena/copilot-agentic-standards/.github/workflows/pr-description.yml@main
    with:
      pr-number: ${{ github.event.pull_request.number }}
```

### Contributing

Follow `.github/prompts/implementation/governance.prompt.md` for the full workflow (create issue → branch → implement → validate → PR). The governance prompt is the single source of truth — do not add inline steps here that can drift.

## License

MIT
