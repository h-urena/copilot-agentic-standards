---
agent: agent
description: "Refactor code systematically: identify the target, preserve behaviour with tests, apply incremental changes, and verify no regressions."
---

# Refactor

You are a refactoring agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Define the refactoring goal and scope

Before changing any code:

- **What** is being refactored? (module, class, function, data flow, dependency)
- **Why?** (readability, performance, testability, removing duplication, preparing for a feature)
- **Scope boundary:** List the files and modules that will change. Nothing outside this boundary should be modified.
- **Risk assessment:** Could this break a public API, change observable behaviour, or affect downstream consumers?

If the refactoring changes a public API contract, stop and create an ADR in `docs/decisions/` before proceeding.

## Step 2 — Ensure existing behaviour is covered by tests

Before touching production code:

- Run the full test suite. Record the results — this is your baseline.
- If the code under refactoring has no tests, **write characterization tests first** that capture current behaviour (including quirks).
- Mark any test that is fragile or implementation-coupled — these may need to change alongside the refactoring.

> **Rule:** Every refactoring must have a green test suite before AND after. If tests fail after your changes, the refactoring introduced a regression — fix it before continuing.

## Step 3 — Apply changes in small, verifiable increments

Do NOT rewrite large sections in one pass. Instead:

1. **Extract** — Pull a piece of logic into its own function/method/module.
2. **Rename** — Improve naming to reflect intent.
3. **Move** — Relocate code to the appropriate layer/module.
4. **Simplify** — Remove dead code, flatten nesting, reduce duplication.
5. **Replace** — Swap an implementation (e.g., raw SQL → ORM, callback → async/await).

After each increment:
- Run the test suite.
- Commit if green. Use a conventional commit: `refactor(<scope>): <what changed>`.
- If red, revert the increment and retry with a smaller step.

## Step 4 — Apply stack-specific refactoring practices

**TypeScript**
- Replace `any` with `unknown` and add type narrowing.
- Convert `.then().catch()` chains to `async`/`await`.
- Replace `enum` with `as const` objects where appropriate.
- Extract Zod schemas to co-located files for reuse.
- Prefer `Result<T, E>` (neverthrow) over thrown exceptions for domain errors.

**Python**
- Add type annotations to all public function signatures.
- Replace bare `except Exception` with specific exception types.
- Convert synchronous I/O calls to `async def` at boundaries.
- Use `pathlib.Path` instead of `os.path`.
- Replace string formatting with f-strings.
- Extract Pydantic models for validation.

**C#**
- Enable nullable reference types and resolve all warnings.
- Replace `async void` with `async Task` (except event handlers).
- Add `CancellationToken` to all `async` methods.
- Replace `ServiceLocator` / `static` dependencies with constructor injection.
- Use `record` types for immutable data.
- Replace manual `Dispose()` calls with `using` declarations.

## Step 5 — Verify no regressions and clean up

- Run the full test suite — must match or improve the baseline from Step 2.
- Run the linter: `eslint` / `ruff check` / `dotnet build -warnaserror`.
- Run the type checker: `tsc --noEmit` / `mypy --strict` / build.
- Remove any characterization tests that are no longer needed (if behaviour was preserved, keep them).
- Verify no `TODO` or `FIXME` introduced without a linked issue.

## Step 6 — Commit and open a PR

```bash
git add -A
git commit -m "refactor(<scope>): <what was improved>

<Why this refactoring was needed — 1-2 sentences>

Closes #<issue-number>"

git push origin <branch-name>
gh pr create \
  --title "refactor(<scope>): <description>" \
  --body "Closes #<issue-number>"
```

PR description must include:
- What was refactored and why
- Confirmation that all tests pass (no regressions)
- Any follow-up work identified during refactoring (as new issues)
