<!-- AUTO-GENERATED — do not edit. Regenerate with: ./scripts/compose.sh python -->
<!-- Source: instructions/base.md + instructions/stacks/python.md -->
<!-- Stack: python -->

# Base Copilot Instructions

These are universal rules that apply to **every** repository regardless of language or framework.

---

## General principles

- Write clear, readable, maintainable code. Prefer simplicity over cleverness.
- Follow the principle of least surprise — code should do what a reader expects.
- Keep functions small and focused. Each function should do one thing well.
- Prefer composition over inheritance.
- Use meaningful, descriptive names for variables, functions, and classes.
- Do not leave dead code, commented-out code, or TODO comments without a linked issue.
- Treat compiler/linter warnings as errors.

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

- Make only the changes required to resolve the issue
- Do not refactor unrelated code or add unrequested features
- If modifying any source file that feeds a composed output, edit the source and regenerate

**Step 5 — Run local validation**

Run all of the following in order. Zero errors allowed — do not proceed with any failing check.

1. **Lint** — run the stack linter. Zero warnings. (Commands in the **Stack validation** section below.)
2. **Type-check** — run the stack type checker in strict mode. Zero errors.
3. **Tests** — run the full test suite. All must pass.
4. **Review prompts** — run before opening the PR. Zero exceptions.
   - `#audit` — every PR without exception.
   - `#security-audit` — any PR touching auth, data access, external inputs, or dependencies.
   - `#dependency-audit` — any PR that adds, removes, or changes a dependency (lockfile, manifest, or version pin).
   - `#performance-audit` — any PR touching database queries, caching, pagination, or frontend bundle output.
5. **Pre-commit hooks** — run `pre-commit run --all-files` if `.pre-commit-config.yaml` exists.
6. **Composed files** — if the repo has `validate-composed.sh`, run it and commit any regenerated
   files before pushing.

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

Do not merge until every required check is green. If any check fails, fix it on the branch and
push again. Never bypass checks.

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

## Branch strategy

- **`main`** is the default, protected branch. All changes merge into `main` via pull request.
- **Every branch must be linked to a GitHub issue.** No issue = no branch = no PR.
- Branch name format: `<type>/<issue-number>-<short-description>`
  - Examples: `feat/42-add-oauth-flow`, `fix/123-null-pointer-crash`, `chore/7-update-deps`
  - Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `hotfix` `bugfix`
  - The slug must be lowercase, hyphen-separated, and start with the issue number.
- Exempt from the naming rule: `main`, `develop`, `staging`, `release/*`, `dependabot/*`, `renovate/*`.
- Delete branches after merge.

## Commit conventions

- Follow [Conventional Commits](https://www.conventionalcommits.org/):
  - `feat:` — new feature
  - `fix:` — bug fix
  - `docs:` — documentation only
  - `style:` — formatting, no logic change
  - `refactor:` — code change that neither fixes a bug nor adds a feature
  - `test:` — adding or updating tests
  - `chore:` — maintenance tasks (deps, CI, tooling)
- Keep the subject line under 72 characters, imperative mood.
- Reference issue/ticket numbers in the commit body when applicable.

## Pull requests

- **Every PR must be linked to a GitHub issue.** Reference it in the PR body with `Closes #N`, `Fixes #N`, or `Resolves #N` so the issue closes automatically on merge.
- PR title **must** follow Conventional Commits format (e.g., `feat(scope): add user auth middleware`).
- Every PR must have a description explaining **what** changed and **why**.
- Squash merge is the default merge strategy. Each PR becomes one commit on `main`.
- PRs must pass all required status checks before merge.
- The repo owner is automatically requested as reviewer when a PR is opened.
- Keep PRs small and focused — one logical change per PR.

## Project board lifecycle

All card transitions are **automated by `project-automation.yml`** — never move cards manually.

| Status          | Automated trigger                                                                                       |
| --------------- | ------------------------------------------------------------------------------------------------------- |
| **Todo**        | Issue created (added to board automatically on `issues: opened`)                                        |
| **In Progress** | Branch matching the issue number is pushed                                                              |
| **In Review**   | PR is opened (owner is auto-assigned as reviewer)                                                       |
| **Done**        | PR is approved → squash auto-merge fires once all required checks pass                                 |

## Code review expectations

- Review for correctness, readability, security, and performance — in that order.
- Suggest improvements, don't demand. Use "nit:" prefix for non-blocking suggestions.
- Approve only when you would be comfortable maintaining the code.
- Flag any hardcoded secrets, credentials, or PII immediately.

## Security

- Never commit secrets, API keys, tokens, or credentials.
- Use environment variables or secret managers for sensitive configuration.
- Validate all external inputs at system boundaries.
- Follow OWASP Top 10 guidelines.
- Keep dependencies up to date; enable Dependabot or Renovate.

## Testing

### Test layers

- **Unit tests**: Test individual public functions, public classes, or public modules in isolation. Mock all external dependencies. Aim for production-level code coverage and critical logic.
- **Integration tests**: Incorporate them if possible: test production interactions between components or with real infrastructure (database, file system, HTTP). Critical for catching contract violations.
- **End-to-end (E2E) tests**: Incorporate them if possible: test complete user flows through the deployed application. Keep the suite lean and focused exclusively on critical paths.

### Standards that apply to all test layers

- Write tests for all new features and bug fixes.
- Aim for meaningful coverage, not raw line-coverage percentages. A green badge on dead code paths is worthless.
- Tests must be deterministic — no flaky tests. A test that fails intermittently is worse than no test.
- Name tests descriptively: `should <expected behavior> when <condition>`.
- Never let a test suite be left in a broken state. Fix or delete flaky tests immediately as part of the same PR.

## CI and GitHub Actions

- Use `GITHUB_TOKEN` for all same-repo workflow operations. It is automatic, expires after the workflow run, and requires no secrets configuration.
- Always declare an explicit `permissions:` block in every workflow. Use job-level permissions for maximum granularity. Grant only what is required.
- For cross-repository or cross-organization write access, prefer a **GitHub App** (installation access token) over a personal access token. For lightweight cases, a **fine-grained PAT** stored as a repository secret is acceptable.
- Never use classic PATs in workflows — they are over-scoped and deprecated. **Exception:** GitHub Projects v2 (`addProjectV2ItemById`) requires the `project` scope, which is only available on classic PATs for personal (non-organisation) accounts. In that specific case, a classic PAT with only the `project` scope is acceptable and should be stored as a repository secret.
- Pin action versions using the major version tag (e.g., `actions/checkout@v6`), not floating tags like `@latest` or `@main`.
- Use `lts/*` for language version inputs (Node.js) and the equivalent latest-stable selector for other runtimes — never hardcode a specific version number in workflow files.

## Shell scripting

- Every script must begin with `set -euo pipefail`.
- Quote all variable expansions: `"$var"`, `"${var}"`. Never leave expansions unquoted.
- All scripts must pass `shellcheck` with zero warnings. **Never suppress a warning with `# shellcheck disable` as a first resort** — fix the root cause instead:
  - SC2016 (dollar sign in single quotes): assign the string using double quotes with `\$` to produce a literal `$` (e.g. `_Q="query(\$id:ID!){...}"` stores `query($id:ID!){...}` without shell expansion). Never use a single-quoted assignment with `$`-containing content — shellcheck fires SC2016 on both the assignment and the call site.
  - SC2086 (unquoted variable): add quotes rather than disabling.
  - Only use `# shellcheck disable` when the flagged construct is provably correct and no clean rewrite exists — always include an inline explanation of _why_.
- Assign long or special-character strings (GraphQL queries, JSON fragments, regex patterns) to named variables before use. Inline literals that trigger linter false positives are a code smell — extract, name, and reference them.
- Use `command -v tool > /dev/null 2>&1` to guard optional tool usage rather than assuming availability.
- Prefer `printf` over `echo` for output that contains escape sequences or user-controlled data.

## Documentation

- Update README and relevant docs alongside code changes.
- Document public APIs, configuration options, and non-obvious decisions.
- Use inline comments sparingly — only for "why", never for "what".

## Dependencies

- Pin dependency versions (exact or range with lockfile).
- Audit new dependencies before adding: check maintenance status, license, bundle size.
- Prefer well-maintained, widely-used packages over obscure alternatives.
- Remove unused dependencies promptly.

## Dependabot PRs

When Dependabot opens a PR, follow these steps without exception:

1. Wait for all CI checks to pass.
2. **Patch or minor bump + green CI** — merge immediately:
   ```bash
   gh pr merge <pr-number> --squash --delete-branch
   ```
3. **Major version bump** — read the package changelog, check for breaking changes, update affected
   code and tests on a new branch (following Steps 1–9 of the pre-flight above), then merge.
4. Never merge a Dependabot PR with failing CI.
5. Never close a Dependabot PR without merging it unless the dependency is being intentionally removed.

## Error handling

- Handle errors explicitly. Do not swallow exceptions silently.
- Use structured error types/codes rather than string matching.
- Log errors with sufficient context for debugging (timestamp, request ID, stack trace).
- Return meaningful error messages to callers; do not expose internal details to end users.
- No problems stated in the 'Problems' tab should be ignored. If a problem is not actionable, it should be suppressed with a comment explaining why. Otherwise, all problems should be addressed before merging.

## Available prompts

Prompts are invocable agent workflows. Invoke with `#<name>` in VS Code Copilot Chat (the filename
without extension). **Use the correct prompt for every task — never implement, fix, scaffold, or
review without invoking the relevant prompt first.**

### Implementation

| Invoke | When to use |
| ------ | ----------- |
| `#governance` | **Before any change** — the full pre-flight workflow (issue → branch → implement → validate → PR → merge) |
| `#implement-feature` | Implementing a new feature end-to-end |
| `#fix-bug` | Diagnosing and fixing a bug — reproduce first, then trace root cause |
| `#write-tests` | Writing tests for existing code |
| `#refactor` | Refactoring without changing observable behaviour |
| `#write-docs` | Generating or updating README, API docs, ADRs, or changelogs |
| `#create-adr` | Recording an architecture decision in `docs/decisions/` |
| `#deploy` | Deploying a service — pre-deploy checks, health verification, rollback plan |
| `#project-kickoff` | Bootstrapping a brand-new project from scratch |

### Review — run these before opening every PR

| Invoke | When to use |
| ------ | ----------- |
| `#audit` | **Every PR** — validate the branch diff against all project standards |
| `#security-audit` | Every PR touching auth, data access, external inputs, or dependencies |
| `#performance-audit` | PRs touching database queries, caching, or frontend bundles |
| `#dependency-audit` | When adding, removing, or upgrading any dependency |

### Scaffolds

| Invoke | When to use |
| ------ | ----------- |
| `#crud-api` | Scaffolding a new CRUD resource (routes, models, validation, tests, migrations) |
| `#auth` | Wiring authentication and authorisation into a project |
| `#database` | Setting up a new database, ORM, migrations, and health checks |
| `#frontend` | Scaffolding a new UI component (structure, a11y, state management, tests) |
| `#background-jobs` | Scaffolding an async worker (queue, retry policy, dead-letter handling) |
| `#notifications` | Scaffolding email, webhook, or push notifications with retry and opt-out |
| `#monorepo` | Scaffolding a multi-service monorepo layout with per-service CI |

### Personas — invoke for a specialist review lens

| Invoke | When to use |
| ------ | ----------- |
| `#architect` | System design, service decomposition, ADR facilitation |
| `#principal-engineer` | Architecture review, abstraction quality, long-term maintainability |
| `#devops-engineer` | CI/CD, containerisation, IaC, secrets management, deployment reliability |
| `#qa-engineer` | Test coverage, quality risks, edge cases, regression strategy |
| `#product-manager` | PRDs, user stories, acceptance criteria, feature scoping |

## Available skills

Skills are specialised knowledge files. Load the relevant file at the start of any task in that
domain — do not rely on general knowledge alone. Skills live in `.github/skills/`.

| Load this file | When |
| -------------- | ---- |
| `.github/skills/test-generation.skill.md` | Writing any test suite |
| `.github/skills/code-analysis.skill.md` | Performing a deep code review or analysis |
| `.github/skills/api-design-review.skill.md` | Reviewing any PR that adds or changes API endpoints |
| `.github/skills/performance-profiling.skill.md` | Investigating or auditing performance |
| `.github/skills/data-migration.skill.md` | Working on any database schema migration or data backfill |

---

# Python Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest stable CPython release unless the project specifies otherwise.
- Use type hints on all public function signatures. Use `from __future__ import annotations` for forward references.
- Enforce type correctness with `mypy --strict` or `pyright` in strict mode as part of CI. Type hints without a checker are documentation, not safety.
- Prefer f-strings over `%` formatting or `.format()`.
- Use `pathlib.Path` over `os.path` for file system operations.
- Never use mutable default arguments (`def f(items=[])`, `def f(cfg={})`). Default to `None` and assign inside the body.
- No wildcard imports (`from module import *`). All public packages must define `__all__`.
- Use context managers (`with`) for all resources: files, database sessions, HTTP clients, locks.

## Project structure

- Use `src/` layout: `src/<package_name>/` with an `__init__.py`.
- Keep tests in a top-level `tests/` directory mirroring the source structure.
- Use `pyproject.toml` as the single source of project metadata — avoid `setup.py` and `setup.cfg`.
- Include a `py.typed` marker file for PEP 561 compliance if the package exposes types.

## Code style

- Use Ruff for linting and formatting (replaces flake8, isort, black).
- Configure Ruff in `pyproject.toml` under `[tool.ruff]`. Enable rule groups: `S` (security), `B` (bugbear), `UP` (pyupgrade), `SIM` (simplify), `PT` (pytest style), `C4` (comprehensions), `A` (builtins shadowing), `N` (naming).
- Maximum line length: 88 characters (Ruff/Black default).
- Use `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.

## Async and concurrency

- Use `asyncio` for IO-bound concurrency. Define `async def` at every IO boundary (network, filesystem, database).
- Use `asyncio.TaskGroup` (Python 3.11+) or `asyncio.gather` for concurrent tasks — do not `await` IO calls sequentially when they can run in parallel.
- Never call blocking functions (`time.sleep`, `requests.get`, sync file IO) inside `async def`. Use `asyncio.to_thread` to offload blocking work.

## Error handling

- Define custom exception classes inheriting from a project-level base exception.
- Never use bare `except:`. Always catch specific exception types.
- Use `raise ... from err` to preserve exception chains.

## Logging and observability

- Use `structlog` for structured JSON logging, or configure the stdlib `logging` module with a JSON formatter. Never use `print()` in production code paths.
- Log at appropriate levels. Include contextual fields (request ID, user ID, operation name) — never log PII or secrets.
- Use `logger.exception()` (not `logger.error()`) when logging inside an `except` block to capture the full stack trace.

## Configuration

- Validate all environment variables at application startup using `pydantic-settings`. Never read `os.environ` inline at call sites — fail fast on missing or malformed config.

## Stack validation

Run these commands in order at Step 5. All must pass with zero errors before committing.

```bash
# Lint — zero errors
ruff check .

# Format check — no unformatted files
ruff format --check .

# Type-check — zero errors (strict mode)
mypy .

# Tests — all must pass
pytest

# Dependency audit — no known vulnerabilities
pip-audit
```

## Testing

- **Unit tests**: Use `pytest`. Mock external dependencies with `pytest-mock` or `unittest.mock`. Follow the Arrange-Act-Assert pattern.
- **Integration tests**: Use real infrastructure (database, HTTP) where possible. Use `pytest-docker` or `testcontainers-python` for reproducible environments.
- **E2E tests**: Use Playwright (`playwright` Python package) for browser automation against a running application.
- Use `pytest-cov` for coverage reporting.
- Use fixtures for shared setup; prefer factory fixtures over complex `parametrize`.
- Name test files `test_<module>.py` and test functions `test_<behavior>_when_<condition>`.

## Dependencies

- Manage dependencies with `uv`, `pip-tools`, or `poetry`. Pin versions in a lockfile.
- Use virtual environments (`venv` or managed by `uv`/`poetry`). Never install globally.
- Separate dev dependencies from runtime dependencies.
- Use `pip audit` or Dependabot to check for known vulnerabilities.

## Packaging and distribution

- Use `hatch`, `flit`, or `setuptools` with `pyproject.toml` as the build backend.
- Version using `__version__` in the package `__init__.py` or dynamic versioning via SCM tags.
- Include `LICENSE`, `README.md`, and `py.typed` in the distribution.
