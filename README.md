# copilot-agentic-standards

Centralized, source-controlled Copilot instructions, reusable workflows, PR templates, MCP configs, and linting baselines — so every repo on the team starts (and stays) consistent.

## Why

Without a single source of truth, every repository drifts: different branch strategies, inconsistent PR titles, missing squash policies, and ad-hoc Copilot instructions. This repo fixes that by providing **composable, stack-aware standards** that any project can adopt with a single bootstrap script.

## Repo structure

```
instructions/          Copilot instruction files (base + per-stack)
  stacks/              Stack-specific additions (typescript, python, csharp)
  code-review.instructions.md
composed/              Pre-merged, ready-to-copy instruction files
workflows/
  reusable/            Reusable GitHub Actions called by consumer repos
  examples/            Example caller workflows
  sync/                Workflow that pulls latest standards into a repo
templates/
  pull-request/        PR templates (default, hotfix)
mcp/                   MCP server configs (base + per-stack)
scripts/               Compose, validate, and onboard automation
```

## Quick start

### 1. Bootstrap an existing repo

```bash
# From the target repo root
curl -sL https://raw.githubusercontent.com/h-urena/copilot-agentic-standards/main/scripts/onboard-repo.sh | bash -s -- --stack typescript
```

Or clone this repo and run locally:

```bash
git clone https://github.com/h-urena/copilot-agentic-standards.git
cd copilot-agentic-standards
./scripts/onboard-repo.sh --repo ../my-project --stack python
```

### 2. Use a composed instruction file directly

Copy a pre-merged file into your repo's `.github/` directory:

```bash
cp composed/typescript-copilot-instructions.md ../my-project/.github/copilot-instructions.md
```

### 3. Keep standards in sync

Add the pull-standards workflow to your repo so it opens a PR whenever this repo updates:

```bash
cp workflows/sync/pull-standards.yml ../my-project/.github/workflows/pull-standards.yml
```

## Composing instructions

The `scripts/compose.sh` script merges `instructions/base.md` with a stack file from `instructions/stacks/` into a single ready-to-use file.

```bash
./scripts/compose.sh typescript   # → composed/typescript-copilot-instructions.md
./scripts/compose.sh python       # → composed/python-copilot-instructions.md
./scripts/compose.sh csharp       # → composed/csharp-copilot-instructions.md
./scripts/compose.sh all          # → all composed files
```

## Validating composed files

CI runs `scripts/validate-composed.sh` to ensure composed files are never stale:

```bash
./scripts/validate-composed.sh    # exits non-zero if any composed file is outdated
```

## Supported stacks

| Stack | Instruction file | MCP config |
|-------|-----------------|------------|
| TypeScript | `instructions/stacks/typescript.md` | `mcp/typescript.mcp.json` |
| Python | `instructions/stacks/python.md` | `mcp/python.mcp.json` |
| C# | `instructions/stacks/csharp.md` | — |

## Workflows

| Workflow | Type | Purpose |
|----------|------|---------|
| `merge-rules.yml` | Reusable | All merge gates: status checks, squash enforcement, commitlint |
| `pr-automation.yml` | Reusable | Auto-assign, label, comment, notify |
| `example-ci.yml` | Example | Shows how a consumer repo calls both reusable workflows |
| `pull-standards.yml` | Sync | Repo-side workflow that opens a PR when standards change |

## Contributing

1. Create a feature branch from `main`
2. Make changes to source files in `instructions/`, `workflows/`, `templates/`, or `mcp/`
3. Run `./scripts/compose.sh all` to regenerate composed files
4. Run `./scripts/validate-composed.sh` to verify
5. Open a PR following the conventional commit format

## License

MIT
