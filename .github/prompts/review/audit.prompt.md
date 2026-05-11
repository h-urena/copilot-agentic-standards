---
agent: audit-engine
description: "Senior Agentic Standards Auditor — run against any branch diff to validate compliance."
---

# Senior Agentic Standards Audit

## Step 0 — Governance

Flag any violation as a blocker before continuing.

```bash
git rev-parse --abbrev-ref HEAD
gh issue view <issue-number>
gh pr view --json body -q .body
```

| Check | Pass condition |
|---|---|
| Branch name | Matches `^(feat\|fix\|docs\|style\|refactor\|perf\|test\|build\|ci\|chore\|hotfix)/\d+-[a-z0-9-]+$` |
| Linked issue | Exists and is open, or was closed by this PR |
| PR body | Contains `Closes #N`, `Fixes #N`, or `Resolves #N` |

---

## Step 1 — Generate diff

```bash
git --no-pager diff main...HEAD > audit_diff.txt
```

---

## Step 2 — Review criteria

### 🔍 Doc Compliance

| Action | Minimum version |
|---|---|
| `actions/checkout` | `@v6` |
| `actions/setup-node` | `@v6` |
| `actions/upload-artifact` | `@v7` |
| `actions/download-artifact` | `@v7` |
| `actions/github-script` | `@v9` |
| `actions/labeler` | `@v6` |
| `actions/setup-python` | `@v6` |
| `actions/setup-dotnet` | `@v5` |

| Rule | Constraint |
|---|---|
| Node runtime | Flag actions bundling Node 20 when a Node 24-compatible release exists |
| `actions/github-script` | Bundles its own Node runtime — `node-version:` is silently ignored; upgrade via major version bump only |
| Modern syntax | Enforce `$GITHUB_OUTPUT`; flag `set-output`, `save-state`, `get-state` as deprecated |
| Shell safety | All `.sh` blocks must open with `set -euo pipefail`; all variables quoted |
| Line length | Max 130 chars per `.yml` line; break with `\`; extract long strings into variables |

---

### 🔄 Logic & Redundancy

| Check | Constraint |
|---|---|
| Sequence | Flag redundant installs or steps that override previous state |
| Contradiction | New steps must not break subsequent logic |
| Idempotency | Steps running on every push must be re-runnable without side effects |

**Regex false positives:** Path-classifying regexes must not match `.md`, `.yml`, or `.json` files — e.g. `/(auth|secret)/i` matches `auth-patterns.instructions.md`. Scope to source extensions or add explicit exclusions.

**`workflow_call` inputs:** Every `context.payload.*` or `${{ inputs.* }}` value must be declared as a `workflow_call` input with a default, or null-checked. A bare `workflow_call: {}` with inline scripts is a red flag.

---

### 🤖 Agentic Clarity (rate 1–10)

`name:` fields at all three levels (workflow, job, step) must be policy statements, not nouns or action verbs — e.g. `Enforce squash-only merge policy`, not `Merge Rules`.

**Branch protection exception:** Job names registered as required status checks must not be renamed — verify under Settings → Branches → Required status checks before flagging.

| Check | Constraint |
|---|---|
| Atomic steps | Chronological only — a later step must not make an earlier one redundant |
| No ambiguity | Each step name self-explanatory with no surrounding context |

---

### 🔒 Zero Hardcoding

| Hardcoded value | Required replacement |
|---|---|
| IDs, tokens, secrets | `${{ secrets.NAME }}` |
| Repo owner / org | `${{ github.repository_owner }}` or `${{ vars.NAME }}` |
| Branch names | `${{ github.event.repository.default_branch }}` or inputs |
| Environment paths | `${{ vars.NAME }}` |

---

### 🎯 Deterministic Behavior

| Rule | Constraint |
|---|---|
| Action pinning | No `@latest`; pin to a specific version |
| Package installs | No `-y` without a version; MCP configs must pin versions |
| CI installs | `npm ci` only, never `npm install` |
| Dependencies | No floating dependencies |

---

## Step 3 — Report findings

```
🏛️ Governance: <finding> — <fix>
🔍 Doc Compliance: <finding> in <file>:<line> — <fix>
🔄 Logic & Redundancy: <finding> — <fix>
🤖 Agentic Clarity: <rating>/10 — <level and current name to improve>
🔒 Zero Hardcoding: <finding> in <file>:<line> — <fix>
🎯 Deterministic Behavior: <finding> in <file>:<line> — <fix>
✅ Refactored Snippet: <only when a code change is required>
```

If no findings in a category, write `PASS`. Apply all fixes directly.

---

## Step 4 — Cleanup

```bash
rm -f audit_diff.txt
```
