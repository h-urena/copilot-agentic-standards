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
