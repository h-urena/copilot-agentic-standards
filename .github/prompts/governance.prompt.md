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

| Key       | Logic        | Target Path                                         |
| :-------- | :----------- | :-------------------------------------------------- |
| **Q1**    | Match(n)     | `.github/prompts/implementation/{{file}}.prompt.md` |
| **Q2**    | Match(n) > 0 | `.github/prompts/scaffolds/{{file}}.prompt.md`      |
| **Q3**    | Match(n) > 0 | `.github/prompts/personas/{{file}}.prompt.md`       |
| **Audit** | Always       | `.github/prompts/review/audit.prompt.md`            |

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
