---
applyTo: "**/*.{ts,tsx}"
---

# TypeScript Code Review Checklist

> Stack-specific additions to the base `code-review.instructions.md`. Flag any violation as blocking unless marked **(nit)**.

---

## Type safety

- [ ] TypeScript strict mode is active (`"strict": true` in `tsconfig.json`). No exceptions have been added.
- [ ] No `any` usage without a `// eslint-disable-next-line` comment with justification.
- [ ] `unknown` is used instead of `any` where the type is genuinely unknown; narrowed before use.
- [ ] No non-null assertions (`!`) without a comment explaining why null is impossible here.
- [ ] `interface` is used for shapes that can be extended; `type` for unions, intersections, and mapped types.

## Runtime validation

- [ ] All external inputs (HTTP request bodies, query params, env vars, API responses) are validated with Zod (or equivalent) at the boundary — TypeScript types alone do not protect against runtime shape violations.
- [ ] Zod schemas are co-located with the route/handler that uses them, not spread across the codebase.
- [ ] Environment variables are validated at startup via a Zod schema (e.g., `t3-env`) — no raw `process.env.THING` access at call sites.

## Async and error handling

- [ ] All `async` functions are properly `await`ed — no floating promises.
- [ ] `catch (error: unknown)` is used; the error is narrowed before access (`instanceof Error` or Zod safeParse).
- [ ] No mixing of callbacks and Promises in the same flow.
- [ ] Recoverable errors (e.g., "user not found") use a `Result<T, E>` type (e.g., `neverthrow`) rather than throwing exceptions.
- [ ] States are modeled as discriminated unions (`{ status: 'loading' } | { status: 'error'; error: Error } | { status: 'success'; data: T }`) — not as combinations of nullable fields or boolean flags.

## Code style (ESLint + Prettier)

- [ ] ESLint passes with no warnings (`@typescript-eslint/recommended` baseline).
- [ ] Prettier formatting is applied.
- [ ] Named exports are used — default exports only where a framework requires them.
- [ ] `const` is used throughout; no `let` unless mutation is required; no `var`.
- [ ] `async/await` is used — no raw `.then().catch()` chains.

## Logging and observability

- [ ] `pino` (or equivalent structured logger) is used for Node.js services — no `console.log` in production paths.
- [ ] Log messages include correlation/request IDs without logging PII, tokens, or full request bodies.
- [ ] Errors logged include the `err` field (pino convention) for stack traces.

## Module and build hygiene

- [ ] `moduleResolution` in `tsconfig.json` is set to `bundler` or `NodeNext` — not the legacy `node` default.
- [ ] New dependencies are added to `devDependencies` when they are build/test-only tools.
- [ ] No circular imports introduced.
- [ ] Barrel files (`index.ts`) are only added at intentional module boundaries.

## Testing

- [ ] Vitest is used for new test files (`vi.mock`, `vi.spyOn`, `@vitest/coverage-v8`).
- [ ] Unit tests mock external dependencies with `vi.mock()` — no real HTTP calls or DB queries.
- [ ] Integration tests use `supertest` + Testcontainers for real infrastructure.
- [ ] E2E tests are in `e2e/` and run against a deployed/preview environment, not localhost.
