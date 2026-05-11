---
applyTo: "**"
---

# Testing Standards

These rules apply to every repository regardless of stack. Stack-specific tooling is in the stack instructions.

## Test pyramid

Maintain this ratio across the test suite:

| Layer | Target share | Scope | Speed |
|-------|-------------|-------|-------|
| Unit | ≥ 70 % | One function, class, or module — no I/O | < 10 ms per test |
| Integration | 20–25 % | One slice (HTTP handler → DB); real infrastructure via containers | < 500 ms per test |
| E2E | ≤ 10 % | Critical user journeys against a deployed environment | seconds |

Never compensate for missing unit tests by writing more integration tests.

## Coverage requirements

- **New code:** minimum **80 % line coverage**, **70 % branch coverage**.
- **Existing code:** do not reduce coverage when modifying a file.
- Coverage is measured in CI on every PR — a drop blocks merge.
- 100 % coverage is not the goal. Aim for coverage of behavior, not lines.

## What to test

**Test behavior, not implementation:**

```
✅ "returns 404 when user does not exist"
❌ "calls userRepository.findById once"
```

**Unit tests must cover:**
- All happy paths
- Every explicit error branch (`if (!user) throw ...`)
- Boundary values (empty string, zero, max int, null)
- All named business rules ("premium users get 3× quota")

**Integration tests must cover:**
- The full request-response cycle for every route
- Database reads and writes (use real DB, not mocks)
- Auth middleware behavior (authenticated, unauthenticated, wrong role)
- At least one sad path per integration boundary

**E2E tests must cover:**
- User registration / login flow
- The single most critical revenue-generating user journey
- Any flow that involves payment or irreversible data mutation

## What to mock

| Mock | Do not mock |
|------|------------|
| External HTTP calls (third-party APIs) | Your own database |
| Email / SMS providers | Your own file system |
| Clock / `Date.now()` for time-sensitive logic | Business logic under test |
| Random / UUID generation for determinism | ORM or query builder |

Use real infrastructure (PostgreSQL, Redis) via **Testcontainers** for integration tests. Never substitute an in-memory fake for a production database — schema differences cause real bugs.

## Test naming

Use a consistent pattern throughout a codebase. Pick one:

```
// Preferred: describe / it with natural language
describe('UserService.deactivate', () => {
  it('marks the user as inactive and revokes all sessions')
  it('throws NotFoundError when user does not exist')
  it('does nothing when user is already inactive')
})

// Also acceptable: given_when_then
def test_deactivate_given_active_user_when_called_marks_inactive():
```

Never name tests `test1`, `testFoo`, or `shouldWork`.

## Test data

- Use **factories or builders** — never duplicate hard-coded fixture objects across test files.
  - TypeScript: `@faker-js/faker` + hand-rolled builders; or `fishery`
  - Python: `factory_boy` + `Faker`
  - C#: `Bogus` / `AutoFixture`
- Isolate test data: each test owns its data and does not rely on data created by another test.
- For database tests: wrap each test in a **transaction that is rolled back** after the test, or truncate tables in a `beforeEach`/`setUp` hook.
- Never commit real PII (real email addresses, real phone numbers) into test fixtures.

## Test organization

- Co-locate unit tests next to the source file they test:
  - `src/users/user.service.ts` → `src/users/user.service.test.ts`
  - `src/users/user_service.py` → `tests/unit/users/test_user_service.py`
  - `UserService.cs` → `UserService.Tests.cs`
- Integration tests live in `tests/integration/`
- E2E tests live in `e2e/`
- Never mix unit and integration tests in the same file.

## Anti-patterns (block PRs that introduce these)

- **Testing internal state** — accessing private fields or methods to assert on them
- **Shared mutable state between tests** — one test's side effects break another
- **Sleep / `Thread.Sleep` / `time.sleep` in tests** — use polling helpers or fake clocks
- **Assertions without messages** on complex conditions — add a message so failures are self-explanatory
- **`expect(true).toBe(true)`** — vacuous assertions that always pass
- **Disabling tests** with `skip` / `xit` / `@pytest.mark.skip` without a linked issue
