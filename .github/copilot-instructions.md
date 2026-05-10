# Copilot instructions for this repo

You are working on the **copilot-agentic-standards** repo — the single source of truth for Copilot
instructions, reusable workflows, PR templates, and MCP configs that get distributed to all downstream
repositories.

## Key context

- `instructions/base.md` is the universal instruction set; all stacks inherit from it.
- Stack-specific files in `instructions/stacks/` are **additive** — they never contradict `base.md`.
- Files in `composed/` are **auto-generated** by `scripts/compose.sh`. Never edit them directly.
- Workflows in `.github/workflows/` use dual triggers (`pull_request` for this repo +
  `workflow_call` for consumers). Files in `workflows/reusable/` are documentation only.

## MANDATORY pre-flight — execute every step, every time, before touching any file

> **STOP.** Do not create, edit, or delete any file until all nine steps below are complete.
> This applies to every change, no matter how small or "obvious".

**Step 1 — Verify main is up to date**

```bash
git checkout main
git pull origin main
```

**Step 2 — Create a GitHub issue**

- Title: `<type>(<scope>): <short description>` using Conventional Commits format
- Body: describe the problem, proposed solution, and acceptance criteria
- Assign to yourself
- Record the issue number — you will need it for every subsequent step

```bash
gh issue create --title "<type>(scope): short description" --body "Problem, solution, acceptance criteria" --assignee @me
```

**Step 3 — Create a branch linked to that issue**

Branch naming format: `<type>/<issue-number>-<short-slug>`

Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `hotfix`

Examples: `feat/42-add-oauth-flow`, `fix/99-null-crash-on-login`, `chore/35-mvp-hardening`

```bash
git checkout -b <type>/<issue-number>-<short-slug>
```

**Step 4 — Implement the change**

Before writing any code, invoke the matching prompt for the task type. Do not start implementing
without it.

**Implementation prompts — invoke at the start of this step based on task type:**

| Task | Invoke |
| ---- | ------ |
| Implementing a new feature | `#feature` |
| Fixing a bug | `#bug` |
| Writing or updating tests | `#test` |
| Refactoring existing code | `#refactor` |
| Writing documentation | `#docs` |
| Recording an architecture decision | `#adr` |
| Deploying a service | `#deploy` |
| Bootstrapping a new project | `#kickoff` |

**Scaffold prompts — invoke at the start of this step when building a new system component:**

| Building | Invoke |
| -------- | ------ |
| A new CRUD resource | `#crud-api` |
| Authentication / authorisation | `#auth` |
| A new database, ORM, or migrations | `#database` |
| A new UI component | `#frontend` |
| An async background worker | `#background-jobs` |
| A notifications system | `#notifications` |
| A multi-service monorepo | `#monorepo` |

**Persona prompts — invoke concurrently when the work touches their domain:**

| Domain | Invoke |
| ------ | ------ |
| System design, service decomposition, or ADR | `#architect` |
| Architecture quality or long-term maintainability concerns | `#principal-engineer` |
| CI/CD, infrastructure, containerisation, or deployment | `#devops-engineer` |
| Test strategy, quality risks, or edge case coverage | `#qa-engineer` |
| Requirements, user stories, or acceptance criteria | `#product-manager` |

> **Agent mode:** `#prompt-name` is human chat syntax. When running as an agent, use `read_file`
> on each prompt's file path instead. The complete path-to-file dispatch tables for Steps 4 and 5
> are in `.github/prompts/governance.prompt.md`.

**Implementation rules (this repo):**

- Make only the changes required to resolve the issue.
- Do not refactor unrelated code or add unrequested features.
- If editing composed files is needed, edit the source (`instructions/`) and regenerate: `./scripts/compose.sh all`

**Step 5 — Run local validation**

```bash
# Lint all shell scripts
shellcheck scripts/*.sh

# Re-compose and verify committed files match
./scripts/compose.sh all
./scripts/validate-composed.sh
```

Fix all errors before continuing. If `validate-composed.sh` reports stale files, commit the regenerated output before pushing.

Run these review prompts before opening the PR — zero exceptions:

- `#audit` — every PR without exception.
- `#security-audit` — any PR touching workflows, scripts, permissions, auth, or external inputs.
- `#dependency-audit` — any PR that adds, removes, or changes a dependency.
- `#performance-audit` — any PR touching database queries, caching, or data-intensive operations.

> **Agent mode:** Use `read_file` on the matching path from the Step 5 dispatch table in
> `.github/prompts/governance.prompt.md`.

**Step 6 — Commit using Conventional Commits**

```bash
git add -A
git commit -m "<type>(<scope>): <description>

<body explaining what and why>

Closes #<issue-number>"
```

> The subject line must be **≤ 100 characters** — `commitlint` enforces this in CI.

**Step 7 — Push and open a Pull Request**

```bash
git push origin <branch-name>
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "Closes #<issue-number>

## Changes
- <what changed and why it matters>

## Why
- <problem solved or requirement met>" \
  --assignee @me
```

**Step 8 — Wait for all CI checks to pass**

Do not merge until every check is green:

- `Validate PR title (Conventional Commits)`
- `Verify squash merge is enabled`
- `Validate branch name`
- `Check composed files are fresh`
- `Lint shell scripts`
- `Tiered Review` (must not have REQUEST_CHANGES findings)

If any check fails, fix it on the branch and push again. Never bypass checks.

**Step 9 — Merge via squash only**

```bash
gh pr merge <pr-number> --squash --delete-branch
```

If you skipped any step, stop immediately, undo your changes (`git checkout main`), and restart from Step 1.

**Non-negotiable rules:**

- Never push directly to `main`
- Never use `--force` on `main`
- Never skip CI
- Every change must trace to an issue number

**Project board:** `project-automation.yml` drives all card transitions automatically. Creating the
issue (Step 2) adds it to **Todo**; pushing the branch moves it to **In Progress**; opening the PR
moves it to **In Review**; merge moves it to **Done**. Never move cards manually.

**Dependabot PRs:** When Dependabot opens a PR, follow these steps without exception:

1. Wait for all CI checks to pass.
2. **Patch or minor bump + green CI** — merge immediately:

   ```bash
   gh pr merge <pr-number> --squash --delete-branch
   ```

3. **Major version bump** — read the package changelog, check for breaking changes, update affected
   code and tests on a new branch (following Steps 1–9 above), then merge.
4. Never merge a Dependabot PR with failing CI.
5. Never close a Dependabot PR without merging it unless the dependency is being intentionally removed.

---

## Rules when editing this repo

1. **Never edit files in `composed/`** — regenerate with `./scripts/compose.sh all`.
2. Keep instructions **declarative and concise**. Use imperative mood ("Use", "Do not", "Prefer").
3. When adding a new stack, create `instructions/stacks/<stack>.md`, add a `mcp/<stack>.mcp.json` if applicable, and update `scripts/compose.sh`.
4. Workflow files must use `workflow_call` trigger for reusable workflows.
5. Follow conventional commits: `feat:`, `fix:`, `docs:`, `chore:`. Add a `scope` when applicable (e.g., `feat(frontend): add UI component`).
6. Shell scripts must pass `shellcheck` with zero warnings and use `set -euo pipefail`. Never
   suppress a warning with `# shellcheck disable` as a first resort — fix the root cause. For
   SC2016 (dollar sign in single quotes), assign the string with double quotes and `\$` to produce
   a literal `$` without shell expansion (e.g. `Q="query(\$id:ID!){...}"`). Single-quoted
   assignment still triggers SC2016 — do not use it.

## Available prompts

Full reference of all available prompts. Invocation rules are in **Step 4** (implementation and
scaffold prompts) and **Step 5** (review prompts). Use this table as a quick reference.

### Implementation — invoke at Step 4 before writing any code

| Invoke | When to use |
| ------ | ----------- |
| `#governance` | **Before any change** — full pre-flight (issue → branch → implement → validate → PR → merge) |
| `#feature` | Implementing a new feature end-to-end |
| `#bug` | Diagnosing and fixing a bug — reproduce first, then trace root cause |
| `#test` | Writing tests for existing code |
| `#refactor` | Refactoring without changing observable behaviour |
| `#docs` | Generating or updating README, API docs, ADRs, or changelogs |
| `#adr` | Recording an architecture decision |
| `#deploy` | Deploying a service — pre-deploy checks, health verification, rollback plan |
| `#kickoff` | Bootstrapping a brand-new project from scratch |

### Review — run at Step 5 before opening the PR

| Invoke | When to use |
| ------ | ----------- |
| `#audit` | **Every PR** — validate the branch diff against all project standards |
| `#security-audit` | Every PR touching workflows, scripts, or permissions |
| `#performance-audit` | PRs touching data-intensive operations |
| `#dependency-audit` | When adding, removing, or upgrading any dependency |

### Scaffolds — invoke at Step 4 when building a new system component

| Invoke | When to use |
| ------ | ----------- |
| `#crud-api` | Scaffolding a new CRUD resource |
| `#auth` | Wiring authentication and authorisation |
| `#database` | Setting up a new database, ORM, migrations |
| `#frontend` | Scaffolding a new UI component |
| `#background-jobs` | Scaffolding an async worker |
| `#notifications` | Scaffolding notifications |
| `#monorepo` | Scaffolding a multi-service monorepo |

### Personas — invoke concurrently at Step 4 when the work touches their domain

| Invoke | When to use |
| ------ | ----------- |
| `#architect` | System design, service decomposition, ADR facilitation |
| `#principal-engineer` | Architecture review, abstraction quality, long-term maintainability |
| `#devops-engineer` | CI/CD, containerisation, IaC, secrets management |
| `#qa-engineer` | Test coverage, quality risks, edge cases |
| `#product-manager` | PRDs, user stories, acceptance criteria |

## Available skills

Skills are specialised knowledge files. Load the relevant file at the start of any task in that
domain. In this repo skills live in `skills/`.

| Load this file | When |
| -------------- | ---- |
| `skills/test-generation.skill.md` | Writing any test suite |
| `skills/code-analysis.skill.md` | Performing a deep code review or analysis |
| `skills/api-design-review.skill.md` | Reviewing any PR that adds or changes API endpoints |
| `skills/performance-profiling.skill.md` | Investigating or auditing performance |
| `skills/data-migration.skill.md` | Working on any database schema migration or data backfill |
