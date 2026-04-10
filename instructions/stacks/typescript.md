# TypeScript Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest LTS version of Node.js unless the project specifies otherwise.
- Use TypeScript strict mode (`"strict": true` in `tsconfig.json`). No exceptions.
- Prefer `const` over `let`. Never use `var`.
- Use `unknown` over `any`. If `any` is unavoidable, add a `// eslint-disable-next-line` with justification.

## Project structure

- Use a `src/` directory for source code and `tests/` (or `__tests__/`) for test files.
- Group by feature/domain, not by file type (e.g., `src/users/` not `src/controllers/`).
- Use barrel files (`index.ts`) sparingly — only at module boundaries.
- Keep `tsconfig.json` at the project root. Use `tsconfig.build.json` for build-specific overrides.

## Code style

- Use ESLint with the project's shared config (extending `@typescript-eslint/recommended`).
- Use Prettier for formatting. Do not mix formatting rules into ESLint.
- Prefer named exports over default exports.
- Use `interface` for object shapes that may be extended; use `type` for unions, intersections, and mapped types.
- Prefer `async/await` over raw Promises. Never mix callbacks and promises.

## Error handling

- Use typed error classes extending `Error` for domain-specific errors.
- Always type catch variables: `catch (error: unknown)` and narrow before using.
- In Express/Fastify, use centralized error-handling middleware — do not catch in every route.

## Testing

- Use Vitest or Jest as the test runner.
- Co-locate test files next to source files or in a mirrored `tests/` directory.
- Mock external dependencies at module boundaries, not deep internals.
- Use `describe`/`it` blocks with descriptive names.

## Dependencies

- Use `npm` or `pnpm` with a lockfile committed to the repo.
- Prefer `devDependencies` for build/test tools. Keep `dependencies` minimal.
- Use `tsx` or `ts-node` for development; compile to JavaScript for production.

## Build and bundling

- Use `tsc` for type-checking. Use a bundler (esbuild, tsup, Vite) for builds.
- Output to a `dist/` directory. Add `dist/` to `.gitignore`.
- Ensure `package.json` has correct `main`, `module`, and `types` fields.
