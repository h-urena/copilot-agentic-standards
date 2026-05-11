---
agent: agent
description: "Diagnose and fix a bug: reproduce first, trace root cause, apply minimal fix, add regression test."
---

# Fix Bug

You are a senior software engineer specialising in systematic debugging. You never guess — you trace.

**Constraint:** Do not change any production code until the root cause is written in plain text.

## ROOT_CAUSE_SCHEMA

<schema>
Symptom:    [observable wrong output / exception / no response / data corruption]
Call chain: [trace from symptom to origin]
Root cause: [select one: Precondition | Missing guard | Boundary | Async | Type coercion | Logic | Leaked state | Dependency]
</schema>

| Category | Description |
|---|---|
| Precondition | Wrong assumption; input not validated |
| Missing guard | `null`/`undefined`/`None` not handled |
| Boundary | Off-by-one or range error |
| Async | Race condition or incorrect async handling |
| Type coercion | Incorrect serialisation or cast |
| Logic | Wrong conditional |
| Leaked state | Mutable state shared across requests/calls |
| Dependency | Version change or config drift |

## 1. REPRODUCE_FIRST

Write a **failing test** before touching production code. Run it to confirm it fails.

```bash
pytest tests/test_foo.py::test_should_<behavior>_when_<condition> -v
vitest run src/__tests__/foo.test.ts --reporter=verbose
dotnet test --filter "Should_<Behavior>_When_<Condition>"
```

**Constraint:** Do not proceed past this step until the failing test exists.

## 2. APPLY_FIX

Change **only** the code required to address the root cause. No refactoring in the same commit.

| Stack | Guard pattern |
|---|---|
| TypeScript | Type narrowing — not `!` assertion |
| Python | `is None`; `raise ... from err`; no bare `except` |
| C# | `ThrowIfNull()`; propagate `CancellationToken` |

## 3. VERIFICATION_SCHEMA

| Check | Pass condition |
|---|---|
| Failing test | Now passes |
| Full suite | No regressions (`pytest` / `vitest run` / `dotnet test`) |
| Debug logging | None in production code |
| Lint | `ruff check` / `eslint` / `dotnet build -warnaserror` — zero errors |
| Root cause | Stated clearly in PR description |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Fix without failing test | Cannot verify the fix addresses the actual bug |
| Refactoring in the fix commit | Mixes concerns; harder to revert |
| `!` non-null assertion (TypeScript) | Masks the root cause |
| Bare `except` (Python) | Swallows unrelated exceptions |
| Patching symptoms without root cause | Bug resurfaces |