---
agent: agent
description: "Governance workflow agent — execute before making any change to this repository."
---

# Governance Workflow

The authoritative 9-step pre-flight is in `.github/copilot-instructions.md` (auto-loaded every
session). Execute it in full — all nine steps, in order. Do not skip any step.

This file supplements Steps 4 and 5 with deterministic prompt dispatch for agent mode.
`#prompt-name` in the pre-flight is human chat syntax. Agents must use `read_file` instead.

---

## Phase 0 — Collect context and build the todo list

**Do this before touching any file or running any command.**

Ask the user the three questions below **as numbered lists** so answers are unambiguous.
If the user already provided sufficient context to answer a question, infer the answer and skip
asking.

### Question 1 — Implementation type (required, pick exactly one)

Present as a numbered list:

1. Implementing a new feature
2. Fixing a bug
3. Writing or updating tests
4. Refactoring existing code
5. Writing documentation
6. Recording an architecture decision
7. Deploying a service
8. Bootstrapping a new project

### Question 2 — New system component (pick one, or 0 for none)

Present as a numbered list:

0. None — not building a new system component
1. CRUD resource
2. Authentication / authorisation
3. Database, ORM, or migrations
4. UI component
5. Async background worker
6. Notifications
7. Multi-service monorepo

### Question 3 — Domains touched (multi-select, or 0 for none)

Present as a numbered list:

0. None of the above
1. System design, service decomposition, or ADR
2. Architecture quality or long-term maintainability
3. CI/CD, infrastructure, containerisation, or deployment
4. Test strategy, quality risks, or edge case coverage
5. Requirements, user stories, or acceptance criteria

---

## Dispatch tables

Map each answer to a concrete file path. Use `read_file` on every matched path.

### Implementation (Question 1 → exactly one path)

| Answer | Load this file |
| ------ | -------------- |
| 1 — New feature | `.github/prompts/implementation/implement-feature.prompt.md` |
| 2 — Bug fix | `.github/prompts/implementation/fix-bug.prompt.md` |
| 3 — Tests | `.github/prompts/implementation/write-tests.prompt.md` |
| 4 — Refactor | `.github/prompts/implementation/refactor.prompt.md` |
| 5 — Documentation | `.github/prompts/implementation/write-docs.prompt.md` |
| 6 — ADR | `.github/prompts/implementation/create-adr.prompt.md` |
| 7 — Deploy | `.github/prompts/implementation/deploy.prompt.md` |
| 8 — New project | `.github/prompts/implementation/project-kickoff.prompt.md` |

### Scaffold (Question 2 → zero or one path)

| Answer | Load this file |
| ------ | -------------- |
| 1 — CRUD resource | `.github/prompts/scaffolds/crud-api.prompt.md` |
| 2 — Auth | `.github/prompts/scaffolds/auth.prompt.md` |
| 3 — Database | `.github/prompts/scaffolds/database.prompt.md` |
| 4 — UI component | `.github/prompts/scaffolds/frontend.prompt.md` |
| 5 — Background worker | `.github/prompts/scaffolds/background-jobs.prompt.md` |
| 6 — Notifications | `.github/prompts/scaffolds/notifications.prompt.md` |
| 7 — Monorepo | `.github/prompts/scaffolds/monorepo.prompt.md` |

### Personas (Question 3 → zero or more paths)

| Answer | Load this file |
| ------ | -------------- |
| 1 — System design / ADR | `.github/prompts/personas/architect.prompt.md` |
| 2 — Architecture quality | `.github/prompts/personas/principal-engineer.prompt.md` |
| 3 — CI/CD / infra | `.github/prompts/personas/devops-engineer.prompt.md` |
| 4 — Test strategy | `.github/prompts/personas/qa-engineer.prompt.md` |
| 5 — Requirements | `.github/prompts/personas/product-manager.prompt.md` |

### Review prompts (Step 5 → always include audit; others depend on the change)

| Load this file | When |
| -------------- | ---- |
| `.github/prompts/review/audit.prompt.md` | **Always** — every PR without exception |
| `.github/prompts/review/security-audit.prompt.md` | PR touches auth, data access, external inputs, or dependencies |
| `.github/prompts/review/dependency-audit.prompt.md` | PR adds, removes, or changes a dependency |
| `.github/prompts/review/performance-audit.prompt.md` | PR touches database queries, caching, or frontend bundles |

---

## Build and present the todo list

Once answers are collected, construct the **concrete** todo list below and present it to the user
for confirmation before starting Step 1. Mark items off as they complete. Do not skip or reorder.

The list is derived mechanically from the answers:
- Include one `Step 4 — load` item per matched implementation path (always one).
- Include one `Step 4 — load` item per matched scaffold path (zero or one).
- Include one `Step 4 — load` item per matched persona path (zero or more, one per persona).
- Include one `Step 5 — review` item per applicable review prompt (always includes audit).
- All other steps are fixed and always present.

```
[ ] Step 1  — Verify main is up to date (git checkout main && git pull)
[ ] Step 2  — Create GitHub issue
[ ] Step 3  — Create branch (<type>/<issue-number>-<slug>)
[ ] Step 4  — Load: <implementation prompt filename>          ← from Question 1
[ ] Step 4  — Load: <scaffold prompt filename>                ← from Question 2 (omit if none)
[ ] Step 4  — Load: <persona prompt filename>                 ← from Question 3 (one per selection, omit if none)
[ ] Step 4  — Implement the change (following all loaded prompts)
[ ] Step 5  — Run stack validation (lint, typecheck, tests)
[ ] Step 5  — Review: audit                                   ← always
[ ] Step 5  — Review: security-audit                          ← omit if not applicable
[ ] Step 5  — Review: dependency-audit                        ← omit if not applicable
[ ] Step 5  — Review: performance-audit                       ← omit if not applicable
[ ] Step 6  — Commit (Conventional Commits, ≤ 100 char subject)
[ ] Step 7  — Push and open Pull Request
[ ] Step 8  — Wait for all CI checks to pass
[ ] Step 9  — Merge via squash (gh pr merge <n> --squash --delete-branch)
```

Replace each `<placeholder>` with the actual filename from the dispatch tables above.

---

## PR body template (Step 7)

```
Closes #<issue-number>

## Changes
- <bullet list of what changed>

## Why
- <reason>
```
