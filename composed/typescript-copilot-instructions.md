<!-- AUTO-GENERATED — do not edit. Regenerate with: ./scripts/compose.sh typescript -->
<!-- Source: instructions/base.md + instructions/stacks/typescript.md -->
<!-- Stack: typescript -->

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
