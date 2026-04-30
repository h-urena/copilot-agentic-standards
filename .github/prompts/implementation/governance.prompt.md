---
agent: agent
description: "Governance workflow agent — execute before making any change to this repository."
---

# Governance Workflow

> The authoritative steps live in `.github/copilot-instructions.md` under
> **MANDATORY pre-flight**. That file is always loaded automatically; this prompt
> is the interactive agent-mode entry point that drives you through those same steps.

Execute the **MANDATORY pre-flight** from `.github/copilot-instructions.md` in full —
all nine steps, in order. Do not skip any step.

## PR body template (Step 7 supplement)

When opening the pull request in Step 7, use this body structure:

```
Closes #<issue-number>

## Changes
- <bullet list of what changed>

## Why
- <reason>
```
