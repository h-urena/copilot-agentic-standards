# Python Stack Instructions

> Additive to `base.md` — these rules apply on top of the universal standards.

---

## Language and runtime

- Target Python 3.11+ unless the project specifies otherwise.
- Use type hints on all public function signatures. Use `from __future__ import annotations` for forward references.
- Prefer f-strings over `%` formatting or `.format()`.
- Use `pathlib.Path` over `os.path` for file system operations.

## Project structure

- Use `src/` layout: `src/<package_name>/` with an `__init__.py`.
- Keep tests in a top-level `tests/` directory mirroring the source structure.
- Use `pyproject.toml` as the single source of project metadata — avoid `setup.py` and `setup.cfg`.
- Include a `py.typed` marker file for PEP 561 compliance if the package exposes types.

## Code style

- Use Ruff for linting and formatting (replaces flake8, isort, black).
- Configure Ruff in `pyproject.toml` under `[tool.ruff]`.
- Maximum line length: 88 characters (Ruff/Black default).
- Use `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants.

## Error handling

- Define custom exception classes inheriting from a project-level base exception.
- Never use bare `except:`. Always catch specific exception types.
- Use `raise ... from err` to preserve exception chains.
- Log exceptions with `logger.exception()` to capture stack traces.

## Testing

- Use `pytest` as the test runner.
- Use `pytest-cov` for coverage reporting.
- Use fixtures for shared setup; prefer factory fixtures over complex parametrize.
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
