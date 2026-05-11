---
agent: governance-engine
description: "Deterministic dispatch & context collector."
---

# Governance Protocol:

## 0. CONTEXT_COLLECTION_SCHEMA

<schema>
Q1: [1:Feature, 2:Bug, 3:Test, 4:Refactor, 5:Docs, 6:ADR, 7:Deploy, 8:Kickoff]
Q2: [0:None, 1:CRUD, 2:Auth, 3:DB, 4:UI, 5:Job, 6:Notify, 7:Mono]
Q3: [0:None, 1:Arch, 2:Principal, 3:DevOps, 4:QA, 5:Product]
</schema>

**Constraint:** Infer values from history. Ask missing via: `Identify [Q1, Q2, Q3]`.

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
4. `read_file` all mapped prompts (Q1, Q2, Q3).
5. **Execution:** Implement feature/fix based on loaded prompts.
6. **Shell Validation:** `shellcheck scripts/*.sh && ./scripts/compose.sh all && ./scripts/validate-composed.sh`.
7. **Gatekeeper:** `read_file ./review/audit.prompt.md` + conditional audits -> Execute review. 
   - *Constraint:* If "Critical" or "Major" issues found, **loop back to Step 5** and fix.
8. **Commit:** `git commit -m` (Conventional).
9. **Promotion:** `gh pr create --body "Audit Passed: [Summary]"` -> Output PR URL.

**STOP EXECUTION. OUTPUT TODO LIST AS MARKDOWN CHECKBOXES. DO NOT PROCEED UNTIL USER REPLIES 'y'.**

## 3. STEP_9_SAFETY_CONTROLS
- **Post-PR:** After successfully creating the PR, ask: *"Enable `gh pr merge --auto --squash`? (y/n)"*. 
- **Constraint:** Do not execute merge or auto-merge flags until this second specific 'y' is received.
