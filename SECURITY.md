# Security Policy

## Supported versions

This repository distributes CI/CD templates, instructions, and workflow files — not a versioned software package. Security fixes are applied to `main` and propagated to consumers via the standard sync workflow.

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities by [creating a private security advisory](https://github.com/h-urena/copilot-agentic-standards/security/advisories/new) in this repository. Include:

- A description of the vulnerability and its potential impact
- Steps to reproduce or a proof-of-concept
- The affected file(s) and line numbers, if applicable

You will receive an acknowledgement within **5 business days** and a resolution or mitigation plan within **30 days**.

## Scope

| Area | In scope |
|------|----------|
| GitHub Actions workflow files (`.github/workflows/`) | ✅ |
| Distributed CI templates (`templates/`) | ✅ |
| Reusable workflows (`workflows/`) | ✅ |
| Copilot instruction files (`instructions/`, `composed/`) | ✅ |
| Scripts (`scripts/`) — shell injection, path traversal | ✅ |

## Supply chain policy

### Action pinning

All GitHub Actions `uses:` references **must** be pinned to a full 40-character commit SHA with the human-readable version in a trailing comment:

```yaml
# Correct
- uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd  # v6.0.2

# Incorrect — mutable tag, do not use
- uses: actions/checkout@v6
```

Pinning is validated by the dependency audit prompt (`.github/prompts/review/dependency-audit.prompt.md`).

### Reusable workflow pinning

All `uses:` references to reusable workflows (including those sourced from this repository) **must** also be pinned to a full 40-character commit SHA with a branch or tag comment. Using a mutable ref such as `@main` means that any future commit — including a malicious one from a compromised account — would automatically run against all consumer repositories:

```yaml
# Correct — pinned to a specific commit SHA
uses: h-urena/copilot-agentic-standards/.github/workflows/pr-automation.yml@86c5acf98f7f2aa66b66f5f728de4f290c3160b0  # main

# Incorrect — mutable ref, supply-chain risk
uses: h-urena/copilot-agentic-standards/.github/workflows/pr-automation.yml@main
```

When the standards repo is updated (e.g., via the `pull-standards` sync workflow), consumer repos **must** update the pinned SHA at the same time. Treat SHA bumps with the same care as dependency upgrades: review the diff between the old and new SHA before merging.

### Adding a new action

Before adding a new third-party action:

1. Review the action's source code and recent commit history.
2. Confirm the action comes from a well-known publisher or has significant community adoption.
3. Pin to the **specific commit SHA** of the version you reviewed.
4. Document the version and date of review in the PR description.

### CVE exception log

If a vulnerability cannot be fixed immediately, it must be tracked here with a mitigation:

| CVE | Package | Severity | Reason unfixed | Mitigation | Target fix date |
|-----|---------|----------|----------------|------------|----------------|
| — | — | — | — | — | — |

When an exception is resolved, remove the row and close the associated tracking issue.
