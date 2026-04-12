---
applyTo: "**/*.cs"
---

# C# Code Review Checklist

> Stack-specific additions to the base `code-review.instructions.md`. Flag any violation as blocking unless marked **(nit)**.

---

## Async / threading

- [ ] Every `async` method accepts a `CancellationToken` parameter and propagates it to all awaitable calls. Omitting it is a blocking violation.
- [ ] No `async void` methods except event handlers. Use `async Task` and propagate exceptions properly.
- [ ] No `.Result`, `.Wait()`, or `.GetAwaiter().GetResult()` — these block threads and cause deadlocks in ASP.NET's synchronization context.
- [ ] `await` is used for all `Task`-returning calls — no fire-and-forget without explicit `_ = Task.Run(...)` and error handling.
- [ ] In library code (not application code): `ConfigureAwait(false)` is applied on all awaits to avoid capturing the synchronization context.

## Null safety

- [ ] Nullable reference types are enabled (`<Nullable>enable</Nullable>`). No new `#nullable disable` suppressions without justification.
- [ ] `ArgumentNullException.ThrowIfNull(param)` (or `ArgumentException.ThrowIfNullOrWhiteSpace` for strings) guards all public method parameters.
- [ ] No `!` null-forgiving operators without a comment explaining why null is structurally impossible.

## Resource management

- [ ] All `IDisposable` / `IAsyncDisposable` objects are disposed via `using` declarations or `await using` — no manual `try/finally` wrapping.
- [ ] No `HttpClient` instantiated directly with `new` — use `IHttpClientFactory`.
- [ ] Database contexts (`DbContext`) are scoped per request and not held as singletons.

## Configuration and DI

- [ ] `IOptions<T>` or `IOptionsSnapshot<T>` is used to consume structured configuration — not `IConfiguration["Key"]` inline.
- [ ] No `ServiceLocator` pattern (no `IServiceProvider.GetService<T>()` at call sites) — inject dependencies through constructors.
- [ ] `record` types are used for immutable DTOs, command/query objects, and configuration models.

## Error handling

- [ ] Exceptions are used for exceptional conditions, not for normal control flow.
- [ ] Domain errors (e.g., "entity not found", "validation failed") use a `Result<T>` or discriminated union (e.g., `ErrorOr<T>`, `OneOf<T, E>`) rather than throwing.
- [ ] ASP.NET endpoints do not catch exceptions per-handler — centralized middleware with `ProblemDetails` is used.
- [ ] `ILogger<T>` is used for all logging. No `Console.WriteLine` in production code.

## EF Core

- [ ] Read-only queries use `.AsNoTracking()` — tracked queries are reserved for operations that will call `SaveChanges`.
- [ ] No raw SQL string concatenation — use `FromSqlRaw` with parameters or `FromSqlInterpolated`.
- [ ] Migrations are code-first and committed to the repo — no pending model changes without a corresponding migration file.
- [ ] N+1 query patterns are avoided: related entities are loaded with `.Include()` / `.ThenInclude()` or explicit projections.

## Health and observability

- [ ] Services expose a `/health` endpoint via `IHealthCheck` registrations.
- [ ] Structured logging with `ILogger<T>` uses message templates (not string interpolation): `_logger.LogInformation("Processing {OrderId}", orderId)`.
- [ ] `Activity` / OpenTelemetry spans are added for non-trivial operations (optional for small services, **(nit)**).

## Testing

- [ ] xUnit is used. Test methods follow `MethodName_Should_ExpectedBehavior_When_Condition` naming.
- [ ] `FluentAssertions` is used for readable assertions.
- [ ] `Testcontainers` (not SQLite in-memory) is used for integration tests that depend on a real database.
- [ ] ASP.NET integration tests use `WebApplicationFactory<T>` — not hand-rolled HTTP clients.
- [ ] Parameterized cases use `[Theory]` with `[InlineData]` or `[MemberData]` — no copy-pasted `[Fact]` methods.
