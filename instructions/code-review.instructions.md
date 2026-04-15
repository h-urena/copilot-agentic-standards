---
applyTo: "**"
---

# Code Review Instructions

> Used by Copilot as a pre-PR automated checklist. Place this file (or include its contents) in `.github/` as `code-review.instructions.md`.

---

## Pre-merge checklist

When reviewing a pull request, verify each of the following. Flag any violations as blocking unless marked (nit).

### Correctness

- [ ] Code does what the PR description claims.
- [ ] Edge cases are handled (null, empty, boundary values).
- [ ] No off-by-one errors in loops or slices.
- [ ] Async operations are properly awaited / resolved.

### Security

- [ ] No secrets, API keys, or credentials in code or config files.
- [ ] User inputs are validated and sanitized at system boundaries.
- [ ] SQL queries use parameterized statements (no string concatenation).
- [ ] Authentication and authorization checks are in place for protected endpoints.
- [ ] Dependencies have no known critical vulnerabilities.

### Style and conventions

- [ ] Code follows the project's established patterns and naming conventions.
- [ ] PR title follows Conventional Commits format.
- [ ] No commented-out code or leftover debug statements (`console.log`, `print`, `Debug.WriteLine`).
- [ ] No unnecessary `any` / `object` / dynamic typing that bypasses the type system.

### Testing

- [ ] New features have unit tests and, where meaningful, integration tests.
- [ ] Bug fixes include a regression test that would have caught the original issue.
- [ ] E2E tests are added or updated for changes to user-facing flows.
- [ ] Test coverage for the changed code has not regressed.
- [ ] Tests are deterministic — no timeouts, sleeps, or flaky assertions.
- [ ] Test names describe the expected behavior, not the implementation.

### Performance

- [ ] No N+1 queries or unnecessary database round-trips.
- [ ] Large collections are paginated or streamed — not loaded entirely into memory.
- [ ] Expensive operations are cached or debounced where appropriate.

### Documentation

- [ ] Public APIs and configuration changes are documented.
- [ ] README is updated if the change affects setup, usage, or architecture.
- [ ] Breaking changes are clearly noted in the PR description.

### Git hygiene

- [ ] PR targets `main` (or the correct base branch).
- [ ] Branch is up to date with `main` — no merge conflicts.
- [ ] Commits are clean — no "fix typo" chains (squash merge handles this).
- [ ] No unrelated changes bundled into the PR.

### CI

- [ ] All required status checks are passing.
- [ ] No new workflow permissions introduced beyond what is necessary.
- [ ] No secrets or environment variables are logged in CI output.
