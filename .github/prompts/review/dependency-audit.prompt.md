---
agent: agent
description: "Audit project dependencies for known vulnerabilities, outdated packages, license risks, and supply-chain hygiene."
---

# Dependency Audit

You are a dependency audit agent. Work through each step in order. Apply all Critical and High fixes directly.

## Step 1 — Run vulnerability scanners

```bash
# TypeScript / Node.js
npm audit --audit-level=moderate

# Python
pip-audit --desc --output json
# or: uv pip audit

# C# / .NET
dotnet list package --vulnerable --include-transitive
```

Record output. Do not proceed until you have scanner results.

## Step 2 — Triage scanner findings

For each vulnerability:

| Field | What to check |
|-------|--------------|
| Severity | Critical / High / Moderate / Low |
| CVSS score | ≥ 9.0 = Critical; 7.0–8.9 = High; 4.0–6.9 = Medium |
| Exploitability | Is the vulnerable code path reachable in this project? |
| Fix available | Is there a patched version? |
| Breaking change | Does upgrading introduce breaking API changes? |

**Do not blindly `npm audit fix --force`** — review each change before applying.

## Step 3 — Fix Critical and High vulnerabilities

For each Critical or High CVE with an available fix:

1. Upgrade the dependency:
   ```bash
   # npm
   npm install package@latest

   # uv / pip
   uv add "package>=X.Y.Z"

   # .NET
   dotnet add package Package --version X.Y.Z
   ```

2. Run the test suite after each upgrade — do not batch all upgrades into one commit.

3. If upgrading is not possible (no fix, breaking change, vendor constraint):
   - Document the exception in a `SECURITY.md` or in-repo threat model
   - Apply a mitigating control (WAF rule, input validation, disable the vulnerable feature)
   - Open a tracking issue

## Step 4 — Outdated dependency review

Identify packages significantly behind latest:

```bash
# Node.js
npm outdated

# Python
uv pip list --outdated

# .NET
dotnet outdated  # requires dotnet-outdated-tool
```

Flag packages that are:
- More than 2 **major** versions behind
- On a version with announced end-of-life
- Known to have performance or security improvements in newer versions

## Step 5 — Supply chain hygiene

### Lockfile integrity
- [ ] `package-lock.json` / `yarn.lock` / `uv.lock` / `packages.lock.json` is committed
- [ ] CI uses the lockfile (`npm ci`, `uv sync --frozen`, `dotnet restore --locked-mode`)
- [ ] Lockfile is regenerated from scratch periodically and reviewed

### Dependency source validation
- [ ] All dependencies come from the official registry (npmjs.com, PyPI, NuGet.org)
- [ ] No packages installed from GitHub raw URLs, private URLs, or file paths in CI
- [ ] No typosquatted package names (check names similar to popular packages)

### Dependabot / Renovate
- [ ] `.github/dependabot.yml` is configured for all ecosystems in use
- [ ] Dependabot PRs are reviewed and merged promptly (not left open for weeks)
- [ ] Auto-merge is configured for patch-level updates with passing tests

### License compliance
Flag any package with a restrictive license that may conflict with the project's license:
- **GPL / AGPL / LGPL** in a proprietary codebase — requires legal review
- **SSPL** (MongoDB, Elasticsearch) — may restrict commercial SaaS use
- **CC-BY-NC** — prohibits commercial use

```bash
# Node.js license check
npx license-checker --onlyAllow "MIT;ISC;Apache-2.0;BSD-2-Clause;BSD-3-Clause;0BSD;Unlicense"

# Python
pip-licenses --format=table
```

## Step 6 — Produce the audit report

```markdown
## Dependency Audit Report

**Project:** <name>
**Date:** <date>
**Ecosystems audited:** <npm / pip / NuGet>

### Critical CVEs (fix immediately)
| Package | Version | CVE | CVSS | Fix |
|---------|---------|-----|------|-----|

### High CVEs (fix this sprint)
| Package | Version | CVE | CVSS | Fix |
|---------|---------|-----|------|-----|

### Outdated packages (review)
| Package | Current | Latest | Status |
|---------|---------|--------|--------|

### Supply chain
- Lockfile committed: ✅ / ❌
- Dependabot configured: ✅ / ❌
- License issues: <list or "none">

### Passed checks
- [ ] No Critical CVEs
- [ ] No High CVEs
- [ ] Lockfile is committed and used in CI
- [ ] All licenses are permissive
- [ ] Dependabot is configured
```
