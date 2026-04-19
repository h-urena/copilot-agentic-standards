---
agent: agent
description: "Implement a feature end-to-end: explore the issue, design a solution, write production code, add tests, self-review, and open a PR — all following project standards."
---

# Implement Feature

You are a software development agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Understand feature scope and affected modules

- Read the linked issue carefully. If acceptance criteria are missing or ambiguous, ask before writing any code.
- Identify which stack(s) are involved (TypeScript, Python, C# — or a combination).
- Identify the modules, services, or layers that need to change.
- If the change could affect a public API contract, list the endpoints or types that will change.

## Step 2 — Produce a written design plan before modifying any file

Write 3–7 bullet points describing your approach before touching any files:

- What will you add / change / remove?
- Where does the change live (layer, module, file)?
- What new abstractions, if any, are introduced?
- What are the main risks or edge cases?

If the design requires an architectural decision, pause and create an ADR (in `docs/decisions/` or equivalent) before proceeding.

## Step 3 — Implement following stack-specific standards

Follow the copilot instructions for the relevant stack(s):

**All stacks**
- Validate all external inputs at the boundary — never deep inside business logic.
  - TypeScript: Zod schema
  - Python: Pydantic model
  - C#: `ArgumentNullException.ThrowIfNull()` + FluentValidation / data annotations
- Handle errors explicitly. No empty `catch` blocks. No silent swallowing.
- Use structured logging — no `console.log`, `print()`, or `Debug.WriteLine()`.
- No secrets or environment-specific values hardcoded in source.
- No dead code. Remove stubs and `TODO`s that are not tracked as follow-up issues.

**TypeScript**
- `unknown` over `any`; `const`-first; named exports.
- Async/await only — no `.then().catch()` chains.
- `Result<T, E>` (neverthrow) for recoverable domain errors.

**Python**
- Type annotations on every function signature; passes `mypy --strict` / `pyright`.
- `async def` at all I/O boundaries; no blocking calls inside `async def`.
- Context managers (`with`) for all resources.

**C#**
- `CancellationToken` in every `async` method signature.
- No `.Result` / `.Wait()`.
- `using` / `await using` for all `IDisposable`.

## Step 4 — Ensure feature is covered by unit, integration, and E2E tests

Write tests **alongside** the implementation, not after.

**Unit tests** (mock all external dependencies)
- Happy path
- Edge cases: empty input, nulls/undefined/None, boundary values
- Error / exception paths
- Test naming: `should <behaviour> when <condition>`
  - Python: `test_<behaviour>_when_<condition>`
  - TypeScript: `it('should <behaviour> when <condition>')`
  - C#: `Should_<Behaviour>_When_<Condition>()`

**Integration tests** (real infrastructure when possible)
- One test per new API endpoint or significant use case.
- Use Testcontainers for DB / queue dependencies — not in-memory fakes.

**E2E tests** (critical user paths only)
- Python / TypeScript: Playwright (`@playwright/test` or `playwright-pytest`)
- Add to `e2e/` directory

**Stack-specific tools**
- Python: `pytest` + `pytest-mock` + `pytest-cov`
- TypeScript: `vitest` + `@vitest/coverage-v8` + `supertest`
- C#: `xUnit` + `FluentAssertions` + `WebApplicationFactory<T>`

## Step 5 — Verify all acceptance criteria are met before committing

Before committing, verify every item:

- [ ] All acceptance criteria from the issue are satisfied
- [ ] No `console.log` / `print()` / debug logging left in production code
- [ ] No hardcoded secrets, tokens, or environment-specific URLs
- [ ] All new / changed public APIs are documented (docstring / JSDoc / XML doc)
- [ ] Linting passes: `ruff check` / `eslint` / `dotnet build -warnaserror`
- [ ] All tests pass: `pytest` / `vitest run` / `dotnet test`
- [ ] No untracked `TODO`s introduced without a linked issue

## Step 6 — Record the implementation and open it for peer review

Follow the governance workflow:

```bash
git add -A
git commit -m "feat(<scope>): <imperative description of what was added>

<Optional: 2-3 sentences on why this approach was chosen>

Closes #<issue-number>"

git push origin <branch-name>
gh pr create \
  --title "feat(<scope>): <description>" \
  --body "Closes #<issue-number>"
```

> **Title constraint:** The commit subject and PR title must be **≤ 100 characters** — `commitlint` enforces `header-max-length` in CI and will block the PR if exceeded.

PR description must include:
- What was implemented
- Key design decisions made
- How it was tested
