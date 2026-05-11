---
agent: audit-engine
description: "Audit project dependencies: vulnerabilities, outdated packages, license risks, supply-chain hygiene."
---

# Dependency Audit

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

## Step 1 — Scan

```bash
npm audit --audit-level=moderate                        # TypeScript / Node.js
pip-audit --desc --output json                          # Python
dotnet list package --vulnerable --include-transitive   # C#
```

---

## Step 2 — Triage findings

| Field | Constraint |
|---|---|
| Severity | Critical / High / Moderate / Low |
| CVSS | ≥ 9.0 = Critical; 7.0–8.9 = High; 4.0–6.9 = Medium |
| Reachability | Is the vulnerable code path reachable in this project? |
| Fix available | Is there a patched version? |
| Breaking change | Does upgrading break API compatibility? |

**Constraint:** Do not run `npm audit fix --force` — review each change before applying.

---

## Step 3 — Fix Critical and High

```bash
npm install package@X.Y.Z            # TypeScript
uv add "package>=X.Y.Z"              # Python
dotnet add package Package --version X.Y.Z   # C#
```

Run the test suite after **each** upgrade — do not batch.

If no fix is available:

| Action | Required |
|---|---|
| Document exception | `SECURITY.md` or in-repo threat model |
| Apply mitigating control | WAF rule, input validation, or feature disable |
| Open tracking issue | Link in exception documentation |

---

## Step 4 — Outdated review

| Flag | Condition |
|---|---|
| Major version lag | More than 2 major versions behind latest |
| End of life | Version has announced EOL |
| Known improvements | Newer version has documented security or performance gains |

---

## Step 5 — Supply chain hygiene

| Check | Pass condition |
|---|---|
| Lockfile committed | `package-lock.json` / `uv.lock` / `packages.lock.json` present |
| CI uses lockfile | `npm ci` / `uv sync --frozen` / `dotnet restore --locked-mode` |
| Registry | All packages from official registry only |
| No URL installs | No GitHub raw URLs or file paths in CI |
| Dependabot | `.github/dependabot.yml` configured for all ecosystems |
| License compliance | No GPL in a proprietary project; all licenses documented |

**License prose:** GPL / AGPL / LGPL in a proprietary codebase requires legal review. SSPL may restrict commercial SaaS use. CC-BY-NC prohibits commercial use. Use `npx license-checker` / `pip-licenses` to enumerate.

---

## Step 6 — Report findings

```
🏛️ Governance: <finding> — <fix>
🔒 Critical CVE: <CVE-ID> in <package>@<version> — <fix>
⚠️ High CVE: <CVE-ID> in <package>@<version> — <fix>
📦 Outdated: <package> at <current> — latest <version> — <action>
🔗 Supply chain: <finding> — <fix>
📄 License: <package> uses <license> — <risk>
✅ Refactored Snippet: <only when a code change is required>
```

If no findings in a category, write `PASS`. Apply all Critical and High fixes directly.

---

## Step 7 — Cleanup

```bash
rm -f pip-audit-output.json
```