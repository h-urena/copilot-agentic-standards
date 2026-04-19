---
mode: agent
description: "Full governance workflow — execute before making any change to this repository."
---

# Governance Workflow

Execute **every step** in order before making any code or config change. Do not skip steps.

## Step 1 — Verify you are on main and it is up to date

```bash
git checkout main
git pull origin main
```

## Step 2 — Create a GitHub issue

- Title: `<type>(<scope>): <short description>` using Conventional Commits format
- Body: describe the problem, proposed solution, and acceptance criteria
- Assign to yourself
- Record the issue number — you will need it for the branch name

```bash
gh issue create --title "<type>(scope): description" --body "..." --assignee @me
```

## Step 3 — Create a feature branch from main

Branch naming format: `<type>/<issue-number>-<short-slug>`

Valid types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `hotfix`

```bash
git checkout -b <type>/<issue-number>-<slug>
```

Examples:
- `feat/42-add-oauth-flow`
- `fix/99-null-crash-on-login`
- `chore/35-mvp-hardening`

## Step 4 — Implement the change

- Make only the changes required to resolve the issue
- Do not refactor unrelated code or add unrequested features
- Follow the rules in `.github/copilot-instructions.md`
- If editing composed files is needed, edit the source (`instructions/`) and regenerate: `./scripts/compose.sh all`

## Step 5 — Run local validation

```bash
# Lint all shell scripts for POSIX compliance and quoting issues
shellcheck scripts/*.sh

# Re-compose all stacks and verify committed files match (exits non-zero if stale)
./scripts/compose.sh all
./scripts/validate-composed.sh
```

Fix any errors before continuing. If `validate-composed.sh` reports stale files, commit the regenerated output before pushing.

## Step 6 — Commit using Conventional Commits

```bash
git add -A
git commit -m "<type>(<scope>): <description>

<body explaining what and why>

Closes #<issue-number>"
```

> **Title constraint:** The first line (`<type>(<scope>): <description>`) must be **≤ 100 characters** — `commitlint` enforces this in CI and will block the PR.

## Step 7 — Push and open a Pull Request

```bash
git push origin <branch-name>
gh pr create \
  --title "<type>(<scope>): <description>" \
  --body "Closes #<issue-number>

## Changes
- <bullet list of what changed>

## Why
- <reason>
" \
  --assignee @me
```

## Step 8 — Wait for CI to pass

All checks must be green before merging:
- `Validate PR title (Conventional Commits)`
- `Verify squash merge is enabled`
- `Validate branch name`
- `Check composed files are fresh`
- `Lint shell scripts`
- `Tiered Review` (automated code review — must not have REQUEST_CHANGES findings)

If any check fails, fix it on the branch and push again. Do **not** bypass checks.

## Step 9 — Merge via squash

Use squash merge only. Merge commits and rebase merges are not allowed.

```bash
gh pr merge <pr-number> --squash --delete-branch
```

---

**Non-negotiable rules:**
- Never push directly to `main`
- Never use `--force` on `main`
- Never skip CI
- Every change must trace to an issue number
