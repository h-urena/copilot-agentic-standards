---
mode: agent
description: "Diagnose and fix a bug systematically: reproduce with a failing test, trace to the root cause, apply the minimal fix, add a regression test, and open a PR."
---

# Fix Bug

You are a debugging agent. Never guess — always trace to the root cause before changing any code.

## Step 1 — Reproduce before touching production code

Write a **failing test** that demonstrates the bug first. This is non-negotiable.

- The test should fail in the current state of the code.
- The test should pass once the bug is fixed.
- If the bug is non-deterministic (race condition, timing-dependent), note this and describe the reproduction conditions manually instead.

```bash
# Run only the new test to confirm it fails
pytest tests/test_foo.py::test_should_<behaviour>_when_<condition> -v
vitest run src/__tests__/foo.test.ts
dotnet test --filter "Should_<Behaviour>_When_<Condition>"
```

Do not proceed to Step 3 until this failing test exists.

## Step 2 — Root-cause analysis

Trace the execution path from the symptom to the root cause:

1. What is the observable symptom? (wrong output, exception thrown, no response, data corruption)
2. Where in the call chain does the failure originate?
3. What is the **root cause**? Choose one:
   - Wrong assumption (precondition not validated)
   - Missing guard (null/undefined/None not handled)
   - Off-by-one or boundary error
   - Race condition or incorrect async handling
   - Incorrect type coercion / serialisation
   - Logic error in a conditional
   - Leaked state between requests / calls
   - Dependency behaving unexpectedly (version change, config drift)
4. Write the root cause in 1–3 sentences. You will include this in the PR description.

**Do not move to Step 3 until you can state the root cause clearly.**

## Step 3 — Apply the minimal fix

- Change **only** the code required to fix the root cause.
- Do not refactor, rename, or clean up unrelated code in the same commit.
- If a refactor is needed to safely apply the fix, do it in a separate commit on the same branch.
- Ensure the fix handles all variants of the bug (different inputs, edge cases, related code paths).

**Stack-specific considerations**
- TypeScript: check for `null` / `undefined` with proper narrowing — not `!` assertion.
- Python: use `is None` checks; avoid bare `except`; use `raise ... from err` for chained exceptions.
- C#: use `ArgumentNullException.ThrowIfNull()`; check `CancellationToken` propagation for async bugs.

## Step 4 — Add / update tests

- The failing test from Step 1 must now pass.
- Add tests for any **additional edge cases** surfaced during root-cause analysis.
- If the bug was in a code path with no existing tests, add unit coverage for the surrounding logic too.
- Ensure the **full existing test suite** still passes — no regressions.

```bash
# Full suite
pytest
vitest run
dotnet test
```

## Step 5 — Verify

- [ ] The failing test from Step 1 now passes
- [ ] No existing tests are broken
- [ ] No debug logging (`console.log`, `print()`, `Debug.WriteLine()`) left in production code
- [ ] The fix does not introduce new linting errors: `ruff check` / `eslint` / `dotnet build -warnaserror`
- [ ] The root cause is clearly understood (not just symptoms patched)

## Step 6 — Commit and open a PR

```bash
git add -A
git commit -m "fix(<scope>): <what was wrong and what the fix does>

Root cause: <1-sentence root cause>
Fix: <1-sentence description of the change>

Closes #<issue-number>"

git push origin <branch-name>
gh pr create \
  --title "fix(<scope>): <description>" \
  --body "Closes #<issue-number>"
```

**PR description must include:**
- **Root cause** — what was wrong and why
- **Fix applied** — what was changed
- **How tested** — which failing test now passes, any additional coverage added
