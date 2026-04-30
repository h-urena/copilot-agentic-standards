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

## Step 4 dispatch — implementation, scaffold, and persona prompts

### 4a — Implementation prompt (required — pick exactly one)

Ask the user: **"What type of change are you making?"**

| Task | Load this file |
| ---- | -------------- |
| Implementing a new feature | `.github/prompts/implementation/implement-feature.prompt.md` |
| Fixing a bug | `.github/prompts/implementation/fix-bug.prompt.md` |
| Writing or updating tests | `.github/prompts/implementation/write-tests.prompt.md` |
| Refactoring existing code | `.github/prompts/implementation/refactor.prompt.md` |
| Writing documentation | `.github/prompts/implementation/write-docs.prompt.md` |
| Recording an architecture decision | `.github/prompts/implementation/create-adr.prompt.md` |
| Deploying a service | `.github/prompts/implementation/deploy.prompt.md` |
| Bootstrapping a new project | `.github/prompts/implementation/project-kickoff.prompt.md` |

Use `read_file` on the matched path. Internalize and follow the loaded instructions before
touching any file.

### 4b — Scaffold prompt (if building a new system component — may be none)

Ask the user: **"Are you building a new system component? If yes, which one?"**

| Component | Load this file |
| --------- | -------------- |
| CRUD resource | `.github/prompts/scaffolds/crud-api.prompt.md` |
| Authentication / authorisation | `.github/prompts/scaffolds/auth.prompt.md` |
| Database, ORM, or migrations | `.github/prompts/scaffolds/database.prompt.md` |
| UI component | `.github/prompts/scaffolds/frontend.prompt.md` |
| Async background worker | `.github/prompts/scaffolds/background-jobs.prompt.md` |
| Notifications | `.github/prompts/scaffolds/notifications.prompt.md` |
| Multi-service monorepo | `.github/prompts/scaffolds/monorepo.prompt.md` |

Use `read_file` on each matched path. Apply scaffold instructions alongside the implementation
prompt.

### 4c — Persona prompts (load all that apply — may be none)

Ask the user: **"Which of these domains does your change touch? Select all that apply."**

| Domain | Load this file |
| ------ | -------------- |
| System design, service decomposition, or ADR | `.github/prompts/personas/architect.prompt.md` |
| Architecture quality or long-term maintainability | `.github/prompts/personas/principal-engineer.prompt.md` |
| CI/CD, infrastructure, containerisation, or deployment | `.github/prompts/personas/devops-engineer.prompt.md` |
| Test strategy, quality risks, or edge case coverage | `.github/prompts/personas/qa-engineer.prompt.md` |
| Requirements, user stories, or acceptance criteria | `.github/prompts/personas/product-manager.prompt.md` |

Use `read_file` on each matched path. Apply persona instructions concurrently.

---

## Step 5 dispatch — review prompts

Run all applicable review prompts before opening the PR. Use `read_file` on each matched path.

| Prompt | Load this file | When |
| ------ | -------------- | ---- |
| audit | `.github/prompts/review/audit.prompt.md` | **Every PR** — no exceptions |
| security-audit | `.github/prompts/review/security-audit.prompt.md` | Any PR touching auth, data access, external inputs, or dependencies |
| dependency-audit | `.github/prompts/review/dependency-audit.prompt.md` | Any PR that adds, removes, or changes a dependency |
| performance-audit | `.github/prompts/review/performance-audit.prompt.md` | Any PR touching database queries, caching, or frontend bundles |

---

## PR body template (Step 7)

```
Closes #<issue-number>

## Changes
- <bullet list of what changed>

## Why
- <reason>
```
