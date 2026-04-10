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

## Branch strategy

- **`main`** is the default, protected branch. All changes merge into `main` via pull request.
- Use short-lived feature branches: `feat/<ticket>-<short-description>`, `fix/<ticket>-<short-description>`, `chore/<description>`.
- Hotfix branches: `hotfix/<ticket>-<short-description>` — branch from `main`, merge back to `main`.
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

- PR title **must** follow Conventional Commits format (e.g., `feat: add user auth middleware`).
- Every PR must have a description explaining **what** changed and **why**.
- Squash merge is the default merge strategy. Each PR becomes one commit on `main`.
- PRs must pass all required status checks before merge.
- Request at least one reviewer. Do not self-merge unless explicitly permitted.
- Keep PRs small and focused — one logical change per PR.

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

### Test layers — all three are required

- **Unit tests**: Test individual functions, classes, or modules in isolation. Mock all external dependencies. Fast and numerous.
- **Integration tests**: Test interactions between components or with real infrastructure (database, file system, HTTP). Fewer than unit tests but critical for catching contract violations.
- **End-to-end (E2E) tests**: Test complete user flows through the deployed application. Slowest — keep the suite lean and focused on critical paths.

### Standards that apply to all test layers

- Write tests for all new features and bug fixes.
- Aim for meaningful coverage, not raw line-coverage percentages. A green badge on dead code paths is worthless.
- Tests must be deterministic — no flaky tests. A test that fails intermittently is worse than no test.
- Name tests descriptively: `should <expected behavior> when <condition>`.
- Never let a test suite be left in a broken state. Fix or delete flaky tests immediately.

## CI and GitHub Actions

- Use `GITHUB_TOKEN` for all same-repo workflow operations. It is automatic, expires after the workflow run, and requires no secrets configuration.
- Always declare an explicit `permissions:` block in every workflow. Use job-level permissions for maximum granularity. Grant only what is required.
- For cross-repository or cross-organization write access, prefer a **GitHub App** (installation access token) over a personal access token. For lightweight cases, a **fine-grained PAT** stored as a repository secret is acceptable.
- Never use classic PATs in workflows — they are over-scoped and deprecated.
- Pin action versions using the major version tag (e.g., `actions/checkout@v4`), not floating tags like `@latest` or `@main`.
- Use `lts/*` for language version inputs (Node.js) and the equivalent latest-stable selector for other runtimes — never hardcode a specific version number in workflow files.

## Documentation

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
