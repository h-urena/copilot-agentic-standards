# Copilot instructions for this repo

You are working on the **copilot-agentic-standards** repo — the single source of truth for Copilot instructions, reusable workflows, PR templates, and MCP configs that get distributed to all downstream repositories.

## Key context

- `instructions/base.md` is the universal instruction set; all stacks inherit from it.
- Stack-specific files in `instructions/stacks/` are **additive** — they never contradict `base.md`.
- Files in `composed/` are **auto-generated** by `scripts/compose.sh`. Never edit them directly.
- Workflows in `.github/workflows/` use dual triggers (`pull_request` for this repo + `workflow_call` for consumers). Files in `workflows/reusable/` are documentation only.

## MANDATORY pre-flight — do this before touching any file

> **STOP.** Do not create, edit, or delete any file until all four steps below are complete.
> This applies to every change, no matter how small or "obvious".

**Step 1 — Verify main is up to date**

```bash
git checkout main && git pull origin main
```

**Step 2 — Create a GitHub issue**

```bash
gh issue create --title "<type>(scope): short description" --body "Problem, solution, acceptance criteria" --assignee @me
```

Record the issue number. You cannot proceed without it.

**Step 3 — Create a branch linked to that issue**

```bash
git checkout -b <type>/<issue-number>-<short-slug>
# e.g. feat/42-add-pr-description-workflow
```

Valid types: `feat` `fix` `docs` `style` `refactor` `perf` `test` `build` `ci` `chore` `hotfix`

**Step 4 — Make ALL changes on that branch, then open a PR**

```bash
gh pr create --title "<type>(scope): description" --body "Closes #<issue-number>"
```

If you skipped any step, stop immediately, undo your changes (`git checkout main`), and restart from Step 1.
The full governance workflow with validation steps is in `.github/prompts/governance.prompt.md`.

---

## Rules when editing this repo

1. **Never edit files in `composed/`** — regenerate with `./scripts/compose.sh all`.
2. Keep instructions **declarative and concise**. Use imperative mood ("Use", "Do not", "Prefer").
3. When adding a new stack, create `instructions/stacks/<stack>.md`, add a `mcp/<stack>.mcp.json` if applicable, and update `scripts/compose.sh`.
4. Workflow files must use `workflow_call` trigger for reusable workflows.
5. Follow conventional commits: `feat:`, `fix:`, `docs:`, `chore:`. Add a `scope` when applicable (e.g., `feat(frontend): add UI component`).
6. Shell scripts must pass `shellcheck` with zero warnings and use `set -euo pipefail`. Never suppress a warning with `# shellcheck disable` as a first resort — fix the root cause. For SC2016 (dollar sign in single quotes), extract the string into a named variable with a single-quoted assignment and expand it with double quotes at the call site.
