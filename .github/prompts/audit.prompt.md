---
agent: agent
description: "Senior Agentic Standards Auditor — run against any branch diff to validate compliance."
---

# Senior Agentic Standards Audit

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

---

### 🔄 Logic & Redundancy

- **Sequence Audit:** Flag redundant installs or steps that override previous state.
- **Contradiction Check:** Ensure new steps do not break subsequent logic.
- **Idempotency:** Steps that run on every push should be idempotent (re-runnable without side effects).

---

### 🤖 Agentic Clarity (rate 1–10)

- **Semantic Intent:** `name:` fields must describe *intent* not just *action*.
  - ❌ `"Check merge method"` — describes the action
  - ✅ `"Check repository merge settings"` — describes the intent
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
🔍 Doc Compliance: <finding> in <file>:<line> — <fix>
🔄 Logic & Redundancy: <finding> — <fix>
🤖 Agentic Clarity: <rating>/10 — <specific step name to improve>
✅ Refactored Snippet: <only if a code change is needed>
```

If no findings in a category, write `PASS`.

Apply all fixes directly. Do not just report — fix.

---

## Step 2 — Remove temporary audit artifacts

```bash
rm audit_diff.txt
```
