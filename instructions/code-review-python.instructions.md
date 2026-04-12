---
applyTo: "**/*.py"
---

# Python Code Review Checklist

> Stack-specific additions to the base `code-review.instructions.md`. Flag any violation as blocking unless marked **(nit)**.

---

## Type safety

- [ ] All public function signatures have type annotations (parameters and return type).
- [ ] `mypy --strict` or `pyright` in strict mode passes with no errors — type hints without a checker are decoration.
- [ ] No use of `Any` without a `# type: ignore` comment explaining why it is unavoidable.
- [ ] `from __future__ import annotations` is present in files that use forward references.

## Python-specific correctness

- [ ] No mutable default arguments (`def f(items=[])` or `def f(cfg={})`). Use `None` and assign inside the function body.
- [ ] No bare `except:` — always catch a specific exception type.
- [ ] `raise ... from err` is used when re-raising to preserve the exception chain.
- [ ] No wildcard imports (`from module import *`).
- [ ] All public packages define `__all__` to explicitly declare their public API.
- [ ] Context managers (`with`) are used for all resources: files, DB sessions, HTTP clients, locks.

## Async

- [ ] `async def` is used at every IO boundary (network, filesystem, database).
- [ ] No `asyncio.sleep(0)` used as a yield — use `asyncio.sleep(0)` only when intentional cooperative yield is needed.
- [ ] `asyncio.gather` or `TaskGroup` (Python 3.11+) is used for concurrent tasks, not sequential `await` chains.
- [ ] No blocking calls (e.g., `time.sleep`, sync file IO, `requests.get`) inside `async def` functions.

## Code style (Ruff)

- [ ] Ruff passes with no warnings. Rule groups `S` (security), `B` (bugbear), `UP` (pyupgrade), `SIM` (simplify), `PT` (pytest), `C4` (comprehensions), `A` (builtins), `N` (naming) are enabled.
- [ ] No f-string usage of `%` or `.format()` for new code.
- [ ] `pathlib.Path` is used instead of `os.path` for filesystem operations.

## Logging and observability

- [ ] `logging` (or `structlog`) is used — no `print()` statements in production code paths.
- [ ] Log messages include enough context (IDs, operation name) without logging PII or secrets.
- [ ] Exceptions are logged with `logger.exception()` (not `logger.error()`) to capture the stack trace.

## Configuration

- [ ] Environment variables are validated at application startup via `pydantic-settings` or equivalent — not read raw from `os.environ` inline.
- [ ] No hardcoded magic strings or config values that should be env vars.

## Testing

- [ ] Test functions follow the `test_<behavior>_when_<condition>` naming pattern.
- [ ] Fixtures are used for shared setup; `parametrize` is used for input variation, not copy-pasted test functions.
- [ ] `pytest-mock` or `unittest.mock` is used to mock external dependencies — no real network/DB calls in unit tests.
- [ ] Coverage has not regressed for the changed module.
