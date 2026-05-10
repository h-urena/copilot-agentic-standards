---
agent: governance-engine
description: "Deterministic dispatch & context collector."
---

# Governance Protocol: [v2.0-Deterministic]

## 0. CONTEXT_COLLECTION_SCHEMA

<schema>
Q1: [1:Feature, 2:Bug, 3:Test, 4:Refactor, 5:Docs, 6:ADR, 7:Deploy, 8:Kickoff]
Q2: [0:None, 1:CRUD, 2:Auth, 3:DB, 4:UI, 5:Job, 6:Notify, 7:Mono]
Q3: [0:None, 1:Arch, 2:Principal, 3:DevOps, 4:QA, 5:Product]
</schema>

**Constraint:** Infer values from chat history. Only ask for missing values using the shorthand: `Identify [Q1, Q2, Q3]`.

## 1. DISPATCH_MAP (read_file)

**Q1** — implementation (always one):

| n | File |
| :- | :--- |
| 1 | `.github/prompts/implementation/feature.prompt.md` |
| 2 | `.github/prompts/implementation/bug.prompt.md` |
| 3 | `.github/prompts/implementation/test.prompt.md` |
| 4 | `.github/prompts/implementation/refactor.prompt.md` |
| 5 | `.github/prompts/implementation/docs.prompt.md` |
| 6 | `.github/prompts/implementation/adr.prompt.md` |
| 7 | `.github/prompts/implementation/deploy.prompt.md` |
| 8 | `.github/prompts/implementation/kickoff.prompt.md` |

**Q2** — scaffold (skip if 0):

| n | File |
| :- | :--- |
| 1 | `.github/prompts/scaffolds/crud-api.prompt.md` |
| 2 | `.github/prompts/scaffolds/auth.prompt.md` |
| 3 | `.github/prompts/scaffolds/database.prompt.md` |
| 4 | `.github/prompts/scaffolds/frontend.prompt.md` |
| 5 | `.github/prompts/scaffolds/background-jobs.prompt.md` |
| 6 | `.github/prompts/scaffolds/notifications.prompt.md` |
| 7 | `.github/prompts/scaffolds/monorepo.prompt.md` |

**Q3** — persona(s) (skip if 0, multi-select):

| n | File |
| :- | :--- |
| 1 | `.github/prompts/personas/architect.prompt.md` |
| 2 | `.github/prompts/personas/principal-engineer.prompt.md` |
| 3 | `.github/prompts/personas/devops-engineer.prompt.md` |
| 4 | `.github/prompts/personas/qa-engineer.prompt.md` |
| 5 | `.github/prompts/personas/product-manager.prompt.md` |

**Audit** — always: `.github/prompts/review/audit.prompt.md`

## 2. DYNAMIC_TODO_GENERATION

1. `git checkout main && git pull`
2. `gh issue create`
3. `git checkout -b <branch>`
4. `read_file` all mapped prompts from Step 1.
5. Execute implementation.
6. `shellcheck scripts/*.sh && ./scripts/compose.sh all && ./scripts/validate-composed.sh`
7. Execute `audit.prompt.md` + conditional audits.
8. `git commit -m` (Conventional).
9. `gh pr create` + `gh pr merge --squash`.

**Wait for 'y' after presenting the Todo List.**
