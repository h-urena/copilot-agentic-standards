---
agent: agent
description: "Senior Agentic Standards Auditor — run against any branch diff to validate compliance."
---

# Senior Agentic Standards Audit

## Step 0 — Verify governance compliance

Before evaluating the code, verify the branch itself followed process. Flag any violation as a
blocker — code correctness is irrelevant if the process was bypassed.

```bash
# 1. Confirm branch name follows <type>/<issue-number>-<slug>
git rev-parse --abbrev-ref HEAD

# 2. Confirm a linked issue exists for the issue number in the branch name
gh issue view <issue-number>

# 3. Confirm the PR body contains Closes/Fixes/Resolves #<issue-number>
gh pr view --json body -q .body
```

| Check | Pass condition |
|-------|---------------|
| Branch name | Matches `^(feat\|fix\|docs\|style\|refactor\|perf\|test\|build\|ci\|chore\|hotfix)/\d+-[a-z0-9-]+$` |
| Linked issue | Issue exists and is open or was closed by this PR |
| PR body | Contains `Closes #N`, `Fixes #N`, or `Resolves #N` |

---

## Step 1 — Generate the branch diff for analysis

```bash
git --no-pager diff main...HEAD > audit_diff.txt
```

Then analyze `audit_diff.txt` against all criteria below.

---

## Review Criteria

### 🔍 Doc Compliance (2026 Standards)

Every `.yml` change **must** use the absolute latest action versions. Flag anything older than:

| Action | Minimum Version |
|---|---|
| `actions/checkout` | `@v6` |
| `actions/setup-node` | `@v5` (prefer `@v6`) |
| `actions/upload-artifact` | `@v5` |
| `actions/download-artifact` | `@v5` |
| `actions/github-script` | `@v9` |
| `actions/labeler` | `@v6` |

**Node runtime:** Flag any action using Node 20 runtime — all actions must be Node 24 compatible.

**Modern syntax:** Enforce `$GITHUB_OUTPUT`. Flag `set-output`, `save-state`, and `get-state` as deprecated.

**Shell:** All `.sh` blocks must start with `set -euo pipefail`. All variables must be quoted.

**Line length:** All `.yml` files are linted with `yamllint` at max 120 characters per line. Flag any line exceeding 120 characters — break long shell lines with `\` continuations and extract long strings into variables.

---

### 🔄 Logic & Redundancy

- **Sequence Audit:** Flag redundant installs or steps that override previous state.
- **Contradiction Check:** Ensure new steps do not break subsequent logic.
- **Idempotency:** Steps that run on every push should be idempotent (re-runnable without side effects).
- **Embedded script correctness:** For any inline JS/shell that classifies files by path (e.g. sensitive paths, test file detection), verify the regex does not produce false positives against documentation, configuration, or instruction files (`.md`, `.yml`, `.json`). A pattern like `/(auth|secret)/i` will match `auth-patterns.instructions.md` — always scope path-matching regexes to source code extensions or add explicit exclusions for non-code file types.
- **`workflow_call` input completeness:** For every workflow that exposes `workflow_call`, verify that every value accessed via `context.payload.*` or `${{ inputs.* }}` inside the job steps is either: (a) declared as a `workflow_call` input with a sensible default, or (b) guarded with a null-check that prevents `core.setFailed` when the payload is absent. A bare `workflow_call: {}` with no inputs is a red flag — check that inline scripts do not silently fail when called externally.

---

### 🤖 Agentic Clarity (rate 1–10)

- **Semantic Intent:** `name:` fields at **all three levels** must describe *intent*, not just *action*:
  - **Workflow `name:`** (top of file) — describes the policy the workflow enforces
  - **Job `jobs.<id>.name:`** — describes the outcome the job ensures
  - **Step `steps[*].name:`** — describes what is being verified or enforced, not the tool being run
  - ❌ `"Check merge method"` / `"PR Description Generator"` — action or noun
  - ✅ `"Enforce squash-only merge policy"` / `"Auto-populate PR Body From Branch Commits"` — policy statement
  - ✅ `"Auto-assign PR to its author"` — policy statement
- **Atomic Instructions:** Markdown must be chronological — Step 5 cannot make Step 2 redundant.
- **No ambiguity:** Step names readable by an LLM with no surrounding context.

---

### 🔒 Zero Hardcoding

Flag **any** hardcoded values that should be dynamic:

- Hardcoded IDs, tokens, or secrets → must use `${{ secrets.NAME }}`
- Hardcoded repo owner/org names → must use `${{ github.repository_owner }}` or `${{ vars.NAME }}`
- Hardcoded branch names → must use `${{ github.event.repository.default_branch }}` or inputs
- Hardcoded paths that vary by environment → must use `${{ vars.NAME }}`

---

### 🎯 Deterministic Behavior

- Actions must be pinned to a specific version (no `@latest`, no `-y` without a version)
- MCP configs must pin package versions
- `npm install` in CI must use `npm ci` (not `npm install`)
- No floating dependencies

---

## Output Format

For each finding:

```
🏛️ Governance: <finding> — <fix>
🔍 Doc Compliance: <finding> in <file>:<line> — <fix>
🔄 Logic & Redundancy: <finding> — <fix>
🤖 Agentic Clarity: <rating>/10 — <specific name: level and value to improve>
✅ Refactored Snippet: <only if a code change is needed>
```

If no findings in a category, write `PASS`.

Apply all fixes directly. Do not just report — fix.

---

## Step 3 — Remove temporary audit artifacts

```bash
rm -f audit_diff.txt
```
