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

## EF Core

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
