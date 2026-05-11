---
agent: agent
description: "Scaffold auth integration: identity provider, middleware, route protection, and auth tests."
---

# Scaffold Auth Integration

**Constraint:** Do not write any code until all required fields in Step 0 are confirmed.

## 0. REQUIREMENTS_SCHEMA

<schema>
IdP:        [Auth0 | Azure AD/Entra ID | Keycloak | Firebase | Supabase | Custom]
Flow:       [Authorization Code | Client Credentials | Device Code]
Token type: [JWT (access + refresh) | Opaque session]
Roles:      [list all role names]
Tenancy:    [Single | Multi]
</schema>

## 1. DEPENDENCY_TABLE

| Stack | Required packages |
|---|---|
| TypeScript | `jose` `jwks-rsa` (pinned with `--save-exact`); IdP SDK if applicable |
| Python | `pyjwt[crypto]` `httpx` `authlib` (pinned via `uv add`) |
| C# | `Microsoft.AspNetCore.Authentication.JwtBearer`; `Microsoft.Identity.Web` (Azure AD) |

**Constraint:** CI must use `npm ci` / `uv sync --frozen` / `dotnet restore --locked-mode`. Never `npm install` in CI.

## 2. ENV_VAR_SCHEMA

| Variable | Required | Description |
|---|---|---|
| `AUTH_ISSUER` | Yes | Token issuer URL |
| `AUTH_AUDIENCE` | Yes | Expected audience claim |
| `AUTH_JWKS_URI` | Yes (RS256) | JWKS endpoint |
| `AUTH_CLIENT_ID` | OAuth flows | OAuth client ID |
| `AUTH_CLIENT_SECRET` | OAuth flows | OAuth client secret |

**Constraint:** All config from environment variables — never hardcoded. Validate at startup; fail fast if missing.

## 3. MIDDLEWARE_REQUIREMENTS

JWT validation must check, in order:

| Check | Failure response |
|---|---|
| Signature (JWKS/RS256 or shared secret/HS256) | 401 Unauthorized |
| Expiry (`exp` claim) | 401 Unauthorized |
| Audience (`aud` claim) | 401 Unauthorized |
| Issuer (`iss` claim) | 401 Unauthorized |
| Role (if required for route) | 403 Forbidden |

## 4. OUTPUT_STRUCTURE

| Stack | File | Purpose |
|---|---|---|
| TypeScript | `src/middleware/auth.ts` | `requireAuth(roles?)` middleware |
| Python | `src/middleware/auth.py` | `get_current_user` dependency + `require_roles` |
| C# | `Program.cs` (configure) + `[Authorize]` attributes | JwtBearer setup |

## 5. TEST_REQUIREMENTS

| Test | Required coverage |
|---|---|
| Valid token | 200 + user context attached |
| Expired token | 401 |
| Wrong audience | 401 |
| Missing token | 401 |
| Insufficient role | 403 |

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Hardcoded secrets or client IDs | Immediate security incident |
| `localStorage` for tokens | XSS-accessible |
| Algorithm `none` accepted | JWT bypass |
| Skipping `aud` or `iss` validation | Accepts tokens from other services |
| Role check inside business logic | Bypassed by different entry points |