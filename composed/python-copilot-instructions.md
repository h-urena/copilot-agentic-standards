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

## Agentic workflow

Before making any code change, always execute these steps in order:

1. **Create a GitHub issue** describing the problem or feature. Use `gh issue create` with a clear title and body.
2. **Create a branch** from `main` following the naming format `<type>/<issue-number>-<short-slug>` (e.g. `feat/42-add-oauth-flow`). Use `git checkout -b`.
3. **Make the changes** on that branch — never commit directly to `main`.
4. **Open a PR** that references the issue with `Closes #N` in the body.

Do not skip or defer any of these steps, even for small or "obvious" fixes.

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

Every issue moves through these statuses automatically via CI:

| Status | Trigger |
|--------|--------|
| **Todo** | Issue created and added to the board |
| **In Progress** | Branch matching the issue number is pushed |
| **In Review** | PR is opened (owner is auto-assigned as reviewer) |
| **Done** | PR is approved → card moves to Done and squash auto-merge is armed; fires once all required checks pass |

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
- Pin action versions using the major version tag (e.g., `actions/checkout@v4`), not floating tags like `@latest` or `@main`.
- Use `lts/*` for language version inputs (Node.js) and the equivalent latest-stable selector for other runtimes — never hardcode a specific version number in workflow files.

## Documentation

- Update README and relevant docs alongside code changes.
- Document public APIs, configuration options, and non-obvious decisions.
- Use inline comments sparingly — only for "why", never for "what".

## Dependencies

- Pin dependency versions (exact or range with lockfile).
- Audit new dependencies before adding: check maintenance status, license, bundle size.
- Prefer well-maintained, widely-used packages over obscure alternatives.
- Remove unused dependencies promptly.

## Error handling

- Handle errors explicitly. Do not swallow exceptions silently.
- Use structured error types/codes rather than string matching.
- Log errors with sufficient context for debugging (timestamp, request ID, stack trace).
- Return meaningful error messages to callers; do not expose internal details to end users.
- No problems stated in the 'Problems' tab should be ignored. If a problem is not actionable, it should be suppressed with a comment explaining why. Otherwise, all problems should be addressed before merging.

---

# Python Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest stable CPython release unless the project specifies otherwise.
- Use type hints on all public function signatures. Use `from __future__ import annotations` for forward references.
- Prefer f-strings over `%` formatting or `.format()`.
- Use `pathlib.Path` over `os.path` for file system operations.

## Project structure

- Use `src/` layout: `src/<package_name>/` with an `__init__.py`.
- Keep tests in a top-level `tests/` directory mirroring the source structure.
- Use `pyproject.toml` as the single source of project metadata — avoid `setup.py` and `setup.cfg`.
- Include a `py.typed` marker file for PEP 561 compliance if the package exposes types.

## Code style

- Use Ruff for linting and formatting (replaces flake8, isort, black).
- Configure Ruff in `pyproject.toml` under `[tool.ruff]`.
- Maximum line length: 88 characters (Ruff/Black default).
- Use `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.

## Error handling

- Define custom exception classes inheriting from a project-level base exception.
- Never use bare `except:`. Always catch specific exception types.
- Use `raise ... from err` to preserve exception chains.
- Log exceptions with `logger.exception()` to capture stack traces.

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
