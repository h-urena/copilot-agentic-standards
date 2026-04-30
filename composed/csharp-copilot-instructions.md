<!-- AUTO-GENERATED — do not edit. Regenerate with: ./scripts/compose.sh csharp -->
<!-- Source: instructions/base.md + instructions/stacks/csharp.md -->
<!-- Stack: csharp -->

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

## MANDATORY pre-flight — do this before touching any file

> **STOP.** Do not create, edit, or delete any file until all four steps below are complete.
> This applies to every change, no matter how small or "obvious".

**Step 1 — Verify main is up to date**

```bash
git checkout main && git pull origin main
```

**Step 2 — Create a GitHub issue**

```bash
gh issue create --title "<type>(scope): short description" --body "Problem, solution, acceptance criteria" --assignee @me
```

Record the issue number. You cannot proceed without it.

**Step 3 — Create a branch linked to that issue**

```bash
git checkout -b <type>/<issue-number>-<short-slug>
# e.g. feat/42-add-pr-description-workflow
```

Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `hotfix`

**Step 4 — Make ALL changes on that branch, then open a PR**

```bash
gh pr create --title "<type>(scope): description" --body "Closes #<issue-number>"
```

If you skipped any step, stop immediately, undo your changes (`git checkout main`), and restart from Step 1.

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

| Status          | Trigger                                                                                                 |
| --------------- | ------------------------------------------------------------------------------------------------------- |
| **Todo**        | Issue created and added to the board                                                                    |
| **In Progress** | Branch matching the issue number is pushed                                                              |
| **In Review**   | PR is opened (owner is auto-assigned as reviewer)                                                       |
| **Done**        | PR is approved → card moves to Done and squash auto-merge is armed; fires once all required checks pass |

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

## Error handling

- Handle errors explicitly. Do not swallow exceptions silently.
- Use structured error types/codes rather than string matching.
- Log errors with sufficient context for debugging (timestamp, request ID, stack trace).
- Return meaningful error messages to callers; do not expose internal details to end users.
- No problems stated in the 'Problems' tab should be ignored. If a problem is not actionable, it should be suppressed with a comment explaining why. Otherwise, all problems should be addressed before merging.

---

# C# Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest LTS version of .NET unless the project specifies otherwise.
- Enable nullable reference types (`<Nullable>enable</Nullable>`) in all projects. No `#nullable disable` suppressions without justification.
- Use file-scoped namespaces and top-level statements where appropriate.
- Prefer `record` types for immutable data transfer objects, command objects, and configuration models.
- Use `ArgumentNullException.ThrowIfNull(param)` (and `ArgumentException.ThrowIfNullOrWhiteSpace` for strings) at the top of every public method to guard parameters explicitly.

## Project structure

- Use the standard .NET solution structure: `src/` for projects, `tests/` for test projects.
- One project per bounded context or domain module.
- Share common code via a `*.Shared` or `*.Common` project — not by copying files.
- Keep the `.sln` file at the repository root.

## Code style

- Follow the [.NET coding conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions).
- Use an `.editorconfig` file to enforce style rules. Enable `dotnet_diagnostic` analyzers.
- Use `PascalCase` for public members, `camelCase` for local variables and parameters, `_camelCase` for private fields.
- Prefer expression-bodied members for single-line methods and properties.

## Async and threading

- Every `async` method **must** accept a `CancellationToken` parameter and propagate it to all awaitable calls. Never ignore or discard cancellation tokens.
- Never use `async void` except for event handlers. Use `async Task` everywhere else so exceptions propagate correctly.
- Never block an async call with `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()`. These block threads and cause deadlocks in ASP.NET's synchronization context.
- In library code (not application code), apply `ConfigureAwait(false)` on all `await` calls to avoid capturing the synchronization context.

## Resource management

- All `IDisposable` and `IAsyncDisposable` objects must be disposed via `using` declarations or `await using` — no manual `try/finally`.
- Never instantiate `HttpClient` directly with `new`. Use `IHttpClientFactory` and register named or typed clients in DI.
- `DbContext` instances must be scoped per request in web applications. Never register them as singletons.

## Configuration

- Consume configuration through `IOptions<T>`, `IOptionsSnapshot<T>`, or `IOptionsMonitor<T>` — never inject `IConfiguration` directly into services and read keys inline.
- Bind configuration sections to strongly-typed `record` or `class` models and validate them on startup (use `ValidateDataAnnotations()` or `ValidateOnStart()`).
- Store environment-specific values in `appsettings.{Environment}.json` or environment variables. Never in source code.

## Error handling

- Use exceptions for exceptional conditions, not for control flow.
- Domain errors (entity not found, validation failed, business rule violations) use a `Result<T>` type — prefer `ErrorOr<T>` (ErrorOr library) or `OneOf<T, E>` over throwing and catching.
- Define domain-specific exception types inheriting from `Exception` for truly exceptional runtime failures.
- Use `ILogger<T>` for structured logging with message templates: `_logger.LogInformation("Processing {OrderId}", orderId)`. Never use `Console.WriteLine` or string interpolation in log calls.
- In ASP.NET, use global exception-handling middleware returning RFC 7807 `ProblemDetails` responses. Do not scatter `try/catch` in every endpoint.

## EF Core data access patterns

- Use `.AsNoTracking()` on all read-only queries. Tracked queries are reserved for operations that call `SaveChangesAsync`.
- Never build queries with raw string concatenation. Use `FromSqlRaw` with parameters or `FromSqlInterpolated`.
- All migrations are code-first and committed to the repository. No manual schema changes without a matching migration file.
- Avoid N+1 query patterns — load related entities with `.Include()` / `.ThenInclude()` or explicit projections. Profile with `EnableSensitiveDataLogging` in development.

## Health and observability

- Every service exposes a `/health` endpoint. Register health checks with `AddHealthChecks()` and map them with `MapHealthChecks("/health")`.
- Add dependency health checks (database, message broker, external APIs) so the health endpoint reflects true service readiness.
- Use `Activity` and OpenTelemetry for distributed tracing in services that participate in a larger system.

## Testing

- **Unit tests**: Use xUnit. Use FluentAssertions for readable assertions. Use `Fact` and `Theory` attributes.
- **Integration tests**: Use `WebApplicationFactory<T>` for ASP.NET integration tests. Use `Testcontainers` to spin up real infrastructure (databases, message brokers) in Docker.
- **E2E tests**: Use Playwright with the .NET binding (`Microsoft.Playwright`) for full browser automation against a running application.
- Name tests: `MethodName_Should_ExpectedBehavior_When_Condition`.
- Prefer `Theory` with `InlineData` or `MemberData` for parameterized tests.

## Dependencies

- Manage NuGet packages with `Directory.Packages.props` for centralized version management.
- Use `dotnet outdated` or Dependabot to track dependency updates.
- Prefer built-in .NET libraries over third-party packages when functionality is equivalent.

## Build and deployment

- Use `dotnet publish` with `--configuration Release` for production builds.
- Enable trimming and AOT compilation where appropriate for performance-critical services.
- Use `Directory.Build.props` for shared MSBuild properties across projects.
- Store environment-specific configuration in `appsettings.{Environment}.json` — never in source code.
