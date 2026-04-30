# TypeScript Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest LTS version of Node.js unless the project specifies otherwise. Pin the version using a `.nvmrc` or `.node-version` file at the project root.
- Use TypeScript strict mode (`"strict": true` in `tsconfig.json`). No exceptions.
- Set `moduleResolution` to `bundler` (for Vite/esbuild projects) or `NodeNext` (for Node.js services). The legacy `node` mode causes subtle import resolution bugs.
- Prefer `const` over `let`. Never use `var`.
- Use `unknown` over `any`. If `any` is unavoidable, add a `// eslint-disable-next-line` with justification.

## Project structure

- Use a `src/` directory for source code and `tests/` (or `__tests__/`) for test files.
- Group by feature/domain, not by file type (e.g., `src/users/` not `src/controllers/`).
- Use barrel files (`index.ts`) sparingly — only at module boundaries.
- Keep `tsconfig.json` at the project root. Use `tsconfig.build.json` for build-specific overrides.

## Code style

- Use ESLint with `@typescript-eslint/recommended` as the base config. Migrate to ESLint's flat config format (`eslint.config.ts`) for new projects.
- Use Prettier for formatting. Do not mix formatting rules into ESLint.
- Prefer named exports over default exports.
- Use `interface` for object shapes that may be extended; use `type` for unions, intersections, and mapped types.
- Prefer `async/await` over raw Promises. Never mix callbacks and promises.

## Runtime validation

- Validate all external inputs (HTTP bodies, query params, API responses, config) with **Zod** (or Valibot) at the system boundary. TypeScript types are erased at runtime; they do not protect against malformed data.
- Co-locate Zod schemas with the route or handler that uses them.
- Validate environment variables at startup with a Zod schema (e.g., `t3-env` or a hand-rolled `z.object({...}).parse(process.env)`). Never access `process.env.THING` at arbitrary call sites.

## Error handling

- Use typed error classes extending `Error` for domain-specific errors.
- Always type catch variables: `catch (error: unknown)` and narrow before using.
- Use a `Result<T, E>` type (e.g., `neverthrow`'s `Result`) for recoverable errors ("user not found", "validation failed") instead of throwing. Reserve exceptions for truly unexpected conditions.
- Model state with discriminated unions (`{ status: 'loading' } | { status: 'error'; error: Error } | { status: 'success'; data: T }`) — avoid parallel nullable fields or boolean flag combinations.
- In Express/Fastify, use centralized error-handling middleware — do not catch in every route.

## Logging and observability

- Use **`pino`** for structured JSON logging in Node.js services. Never use `console.log` in production code paths.
- Pass a child logger with request-scoped context (request ID, user ID) through the call chain — use `logger.child({ requestId })` per request.
- Log at appropriate levels. Never log PII, tokens, or full request/response bodies.

## Stack validation

Run these commands in order at Step 5. All must pass with zero errors before committing.

```bash
# Lint — zero ESLint errors or warnings
npm run lint

# Type-check — zero TypeScript errors (strict mode)
npm run typecheck

# Tests — all must pass
npm test

# Dependency audit — no high or critical vulnerabilities
npm audit --audit-level=high
```

If the project uses `pnpm`, substitute `pnpm run lint`, `pnpm run typecheck`, `pnpm test`, `pnpm audit --audit-level=high`.

## Testing

- **Unit tests**: Use **Vitest** for all new TypeScript projects. It has native TypeScript/ESM support (no `ts-jest` wrapper), a Jest-compatible API (`describe`/`it`/`expect`), and runs significantly faster. Use Jest only if a project is already committed to it — the migration cost is low, but don't migrate just to migrate.
  - Use `vi.mock()` for module mocking, `vi.spyOn()` for spying.
  - Use `@vitest/coverage-v8` for coverage reports (faster than istanbul).
- **Integration tests**: Use `supertest` for HTTP-level integration tests against Express/Fastify/Hono handlers. Use `@testcontainers/testcontainers` to spin up real infrastructure (databases, queues) in Docker for true integration coverage.
- **E2E tests**: Use `@playwright/test` for browser automation. Keep the suite lean — critical user flows only. Run E2E against a deployed preview environment, not localhost.
- Co-locate unit/integration test files next to source files (`*.test.ts`) or mirror structure in `tests/`. Keep E2E tests in a top-level `e2e/` directory.

## Dependencies

- Use `npm` or `pnpm` with a lockfile committed to the repo.
- Prefer `devDependencies` for build/test tools. Keep `dependencies` minimal.
- Use `tsx` or `ts-node` for development; compile to JavaScript for production.

## Build and bundling

- Use `tsc` for type-checking. Use a bundler (esbuild, tsup, Vite) for builds.
- Output to a `dist/` directory. Add `dist/` to `.gitignore`.
- Ensure `package.json` has correct `main`, `module`, and `types` fields.
