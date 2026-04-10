# Copilot instructions for this repo

You are working on the **copilot-agentic-standards** repo — the single source of truth for Copilot instructions, reusable workflows, PR templates, and MCP configs that get distributed to all downstream repositories.

## Key context

- `instructions/base.md` is the universal instruction set; all stacks inherit from it.
- Stack-specific files in `instructions/stacks/` are **additive** — they never contradict `base.md`.
- Files in `composed/` are **auto-generated** by `scripts/compose.sh`. Never edit them directly.
- Workflows in `.github/workflows/` use dual triggers (`pull_request` for this repo + `workflow_call` for consumers). Files in `workflows/reusable/` are documentation only.

## Rules when editing this repo

1. **Never edit files in `composed/`** — regenerate with `./scripts/compose.sh all`.
2. Keep instructions **declarative and concise**. Use imperative mood ("Use", "Do not", "Prefer").
3. When adding a new stack, create `instructions/stacks/<stack>.md`, add a `mcp/<stack>.mcp.json` if applicable, and update `scripts/compose.sh`.
4. Workflow files must use `workflow_call` trigger for reusable workflows.
5. Follow conventional commits: `feat:`, `fix:`, `docs:`, `chore:`. Add a `scope` when applicable (e.g., `feat(frontend): add UI component`).
6. Shell scripts must pass `shellcheck` and use `set -euo pipefail`.
