---
agent: agent
description: "Record an Architecture Decision: capture context, options considered, decision made, and consequences — in the project's docs/decisions/ directory."
---

# Create Architecture Decision Record

You are an ADR-writing agent. Work through the steps below. ADRs are permanent records — write them as if the next engineer has no context from this conversation.

## Step 1 — Gather the decision context

Answer these questions before writing anything:

- **What is the decision?** One sentence describing the architectural choice to be made.
- **What is the problem or constraint driving it?** Why does this decision need to be made now?
- **What are the non-negotiable requirements?** (performance, security, cost, team capability, timeline)
- **What are the options under consideration?** List at least two; document why each was considered.

If any of these are unclear, ask the user before proceeding.

## Step 2 — Evaluate each option

For each option, document:

| Dimension | Option A | Option B | Option N |
|-----------|---------|---------|---------|
| Fits requirements | | | |
| Operational complexity | | | |
| Team familiarity | | | |
| Cost (infrastructure + dev time) | | | |
| Reversibility | | | |
| Alignment with existing stack | | | |

Score honestly. Do not write a lopsided evaluation that only exists to justify a foregone conclusion.

## Step 3 — Write the ADR file

Create the file at `docs/decisions/YYYYMMDD-<slug>.md` using the template below. Use today's date.

```markdown
# ADR-NNNN: <Title — concise noun phrase describing the decision>

**Date:** YYYY-MM-DD
**Status:** Accepted  <!-- Proposed | Accepted | Deprecated | Superseded by ADR-XXXX -->
**Deciders:** <names or roles of people who made or reviewed this decision>

## Context

<!-- 2–4 sentences: what situation or constraint is forcing this decision?
     Assume the reader has no background. -->

## Decision

<!-- One clear sentence: "We will use X for Y because Z." -->

## Options considered

### Option A — <Name>

**Summary:** <one sentence>

**Pros:**
- <specific advantage>

**Cons:**
- <specific disadvantage>

### Option B — <Name>

**Summary:** <one sentence>

**Pros:**
- <specific advantage>

**Cons:**
- <specific disadvantage>

## Consequences

### Positive
- <what gets better as a result of this decision>

### Negative
- <what becomes harder or worse — be honest>

### Neutral / open questions
- <things to revisit once this is implemented>

## Implementation notes

<!-- Optional: key implementation details, migration steps, or links to follow-up issues -->
```

## Step 4 — Link the ADR to its trigger

- If this ADR was created as part of a feature implementation, add a link to it in the PR description.
- If it supersedes an older ADR, update the old ADR's `Status` to `Superseded by ADR-NNNN`.
- If it creates follow-up action items, open GitHub issues and link them in the ADR.

## Step 5 — Commit the ADR

```bash
git add docs/decisions/YYYYMMDD-<slug>.md
git commit -m "docs(adr): <title>"
```

The ADR commit should be separate from the implementation commit so it is easy to find in history.
