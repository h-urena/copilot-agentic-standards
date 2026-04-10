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

- Write tests for all new features and bug fixes.
- Aim for meaningful coverage, not 100% line coverage at the expense of useful tests.
- Tests should be deterministic — no flaky tests allowed.
- Name tests descriptively: `should <expected behavior> when <condition>`.

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

---

# C# Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest LTS version of .NET (currently .NET 8) unless the project specifies otherwise.
- Enable nullable reference types (`<Nullable>enable</Nullable>`) in all projects.
- Use file-scoped namespaces and top-level statements where appropriate.
- Prefer `record` types for immutable data transfer objects.

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

## Error handling

- Use exceptions for exceptional conditions, not for control flow.
- Define domain-specific exception types inheriting from `Exception`.
- Use `ILogger<T>` for structured logging. Never use `Console.WriteLine` in production code.
- In ASP.NET, use global exception handling middleware with `ProblemDetails` responses.

## Testing

- Use xUnit as the test framework. Use FluentAssertions for readable assertions.
- Use the `Fact` and `Theory` attributes. Prefer `Theory` with `InlineData` for parameterized tests.
- Name tests: `MethodName_Should_ExpectedBehavior_When_Condition`.
- Use `WebApplicationFactory<T>` for integration tests in ASP.NET projects.

## Dependencies

- Manage NuGet packages with `Directory.Packages.props` for centralized version management.
- Use `dotnet outdated` or Dependabot to track dependency updates.
- Prefer built-in .NET libraries over third-party packages when functionality is equivalent.

## Build and deployment

- Use `dotnet publish` with `--configuration Release` for production builds.
- Enable trimming and AOT compilation where appropriate for performance-critical services.
- Use `Directory.Build.props` for shared MSBuild properties across projects.
- Store environment-specific configuration in `appsettings.{Environment}.json` — never in source code.
