# Python Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target the latest stable CPython release unless the project specifies otherwise.
- Use type hints on all public function signatures. Use `from __future__ import annotations` for forward references.
- Enforce type correctness with `mypy --strict` or `pyright` in strict mode as part of CI. Type hints without a checker are documentation, not safety.
- Prefer f-strings over `%` formatting or `.format()`.
- Use `pathlib.Path` over `os.path` for file system operations.
- Never use mutable default arguments (`def f(items=[])`, `def f(cfg={})`). Default to `None` and assign inside the body.
- No wildcard imports (`from module import *`). All public packages must define `__all__`.
- Use context managers (`with`) for all resources: files, database sessions, HTTP clients, locks.

## Project structure

- Use `src/` layout: `src/<package_name>/` with an `__init__.py`.
- Keep tests in a top-level `tests/` directory mirroring the source structure.
- Use `pyproject.toml` as the single source of project metadata — avoid `setup.py` and `setup.cfg`.
- Include a `py.typed` marker file for PEP 561 compliance if the package exposes types.

## Code style

- Use Ruff for linting and formatting (replaces flake8, isort, black).
- Configure Ruff in `pyproject.toml` under `[tool.ruff]`. Enable rule groups: `S` (security), `B` (bugbear), `UP` (pyupgrade), `SIM` (simplify), `PT` (pytest style), `C4` (comprehensions), `A` (builtins shadowing), `N` (naming).
- Maximum line length: 88 characters (Ruff/Black default).
- Use `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.

## Async

- Use `asyncio` for IO-bound concurrency. Define `async def` at every IO boundary (network, filesystem, database).
- Use `asyncio.TaskGroup` (Python 3.11+) or `asyncio.gather` for concurrent tasks — do not `await` IO calls sequentially when they can run in parallel.
- Never call blocking functions (`time.sleep`, `requests.get`, sync file IO) inside `async def`. Use `asyncio.to_thread` to offload blocking work.

## Error handling

- Define custom exception classes inheriting from a project-level base exception.
- Never use bare `except:`. Always catch specific exception types.
- Use `raise ... from err` to preserve exception chains.
- Log caught exceptions with `logger.exception()` to capture the full stack trace.

## Logging and observability

- Use `structlog` for structured JSON logging, or configure the stdlib `logging` module with a JSON formatter. Never use `print()` in production code paths.
- Log at appropriate levels. Include contextual fields (request ID, user ID, operation name) — never log PII or secrets.
- Use `logger.exception()` (not `logger.error()`) when logging inside an `except` block to capture the full stack trace.

## Configuration

- Validate all environment variables at application startup using `pydantic-settings`. Never read `os.environ` inline at call sites — fail fast on missing or malformed config.

## Testing

- **Unit tests**: Use `pytest`. Mock external dependencies with `pytest-mock` or `unittest.mock`. Follow the Arrange-Act-Assert pattern.
- **Integration tests**: Use real infrastructure (database, HTTP) where possible. Use `pytest-docker` or `testcontainers-python` for reproducible environments.
- **E2E tests**: Use Playwright (`playwright` Python package) for browser automation against a running application.
- Use `pytest-cov` for coverage reporting.
- Use fixtures for shared setup; prefer factory fixtures over complex `parametrize`.
- Name test files `test_<module>.py` and test functions `test_<behavior>_when_<condition>`.

## Dependencies

- Manage dependencies with `uv`, `pip-tools`, or `poetry`. Pin versions in a lockfile.
- Use virtual environments (`venv` or managed by `uv`/`poetry`). Never install globally.
- Separate dev dependencies from runtime dependencies.
- Use `pip audit` or Dependabot to check for known vulnerabilities.

## Packaging and distribution

- Use `hatch`, `flit`, or `setuptools` with `pyproject.toml` as the build backend.
- Version using `__version__` in the package `__init__.py` or dynamic versioning via SCM tags.
- Include `LICENSE`, `README.md`, and `py.typed` in the distribution.
