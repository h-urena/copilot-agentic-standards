---
agent: audit-engine
description: "Security audit: OWASP Top 10, secrets exposure, dependency risks, infrastructure misconfigurations."
---

# Security Audit

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

## Step 1 — Generate diff

```bash
git --no-pager diff main...HEAD > audit_diff.txt
```

---

## Step 2 — Review criteria

### 🔒 Secrets and sensitive data

| Pattern to search | Action |
|---|---|
| `password`, `secret`, `api_key`, `token`, `Bearer`, `sk-`, `pk_`, `AKIA` | Move to env vars / secrets manager; rotate immediately |
| `BEGIN RSA PRIVATE KEY`, `BEGIN EC PRIVATE KEY`, `BEGIN OPENSSH PRIVATE KEY` | Remove from history; rotate key |
| Connection strings with inline credentials | Move to env vars |
| PII in code or comments | Remove |
| `.env`, `.env.local`, `.env.production` committed | Add to `.gitignore`; rotate all values |

---

### 🔐 Authentication and authorisation

| Check | Pass condition |
|---|---|
| JWT validation | Signature + `exp` + `aud` + `iss` all checked |
| Token storage | HttpOnly cookies — never `localStorage` for sensitive tokens |
| Session IDs | Cryptographically random; regenerated on privilege change |
| Password hashing | `bcrypt` (cost ≥ 12) / `argon2` / `scrypt` — never MD5/SHA1/SHA256 alone |
| Endpoint auth | Every endpoint has explicit auth check — no auth by obscurity |
| IDOR | Users can only access their own resources |
| Role checks | At controller/handler level — not buried in business logic |

---

### 💉 Injection vectors

| Vector | Pass condition |
|---|---|
| SQL | Parameterised queries or ORM only — no string concatenation |
| XSS | Input escaped before HTML render; CSP headers configured |
| Command | No user input in `exec`/`subprocess`/`Process.Start`; allowlist if unavoidable |
| Path traversal | File paths from user input validated; no `../`; allowlisted directories |
| Deserialisation | No `pickle.loads`, `BinaryFormatter`, `eval` on untrusted data |

**Prose rationale — XSS auto-escaping:** React/Angular/Blazor auto-escaping is bypassed by `dangerouslySetInnerHTML`, `[innerHTML]`, and `MarkupString`. Flag any use of these on user-controlled content.

---

### 📦 Dependency security

| Check | Pass condition |
|---|---|
| Known CVEs | `npm audit` / `pip audit` / `dotnet list package --vulnerable` — no Critical/High unmitigated |
| Lockfile in CI | `npm ci` / `uv sync --frozen` / `dotnet restore --locked-mode` |
| Dependabot | Configured for all ecosystems |

---

### 🐳 Infrastructure

| Check | Pass condition |
|---|---|
| Base image | Specific tag — no `:latest` |
| Non-root | `USER appuser` in every Dockerfile |
| No secrets in build | No secrets in Dockerfile or build args |
| CI permissions | Least-privilege `permissions:` block per job |
| HTTPS | All external communication over HTTPS; HSTS configured |
| CORS | Allowed origins explicitly listed — no `*` in production |
| Error responses | No stack traces, internal paths, or SQL in production responses |
| Rate limiting | Auth endpoints rate-limited |

---

## Step 3 — Report findings

```
🔒 Secrets: <finding> in <file>:<line> — <fix>
🔐 Auth: <finding> — <fix>
💉 Injection: <finding> in <file>:<line> — <fix>
📦 Dependency: <CVE or finding> — <fix>
🐳 Infrastructure: <finding> — <fix>
✅ Refactored Snippet: <only when a code change is required>
```

Severity tiers:
- **Blocker** — Critical/High CVE, exposed secret, missing auth check, injection vector
- **Warning** — Moderate CVE, missing HSTS, weak password hashing
- **Suggestion** — Rate limiting gaps, CORS hardening, error message verbosity

If no findings in a category, write `PASS`. Apply all Blocker findings directly.

---

## Step 4 — Cleanup

```bash
rm -f audit_diff.txt
```