---
agent: agent
description: "Wire authentication and authorization into a project: configure the identity provider, implement middleware, protect routes, and add auth tests."
---

# Scaffold Auth Integration

You are an auth integration agent. Work through the steps below in order. Do not skip steps.

## Step 1 — Determine auth requirements

Before writing any code, confirm:

- **Identity provider:** Auth0, Azure AD / Entra ID, Keycloak, Firebase Auth, Supabase Auth, or custom
- **Auth flow:** Authorization Code (web apps), Client Credentials (service-to-service), Device Code (CLI)
- **Token type:** JWT (access + refresh) or opaque session tokens
- **Roles/permissions:** What roles exist? (e.g., `user`, `admin`, `editor`)
- **Multi-tenancy:** Single tenant or multi-tenant?

## Step 2 — Install dependencies and configure the provider

**TypeScript**
```bash
# Use --save-exact to pin to a specific version; commit the resulting package-lock.json.
# CI must use `npm ci` (not `npm install`) to install from the lockfile.
npm install --save-exact jose jwks-rsa                # JWT validation
npm install --save-exact @auth0/nextjs-auth0          # Auth0 (if applicable)
npm install --save-exact passport passport-jwt        # Express/Fastify (if applicable)
```

**Python** (project standard: `uv`)
```bash
# uv add pins to the resolved version in uv.lock; commit the lockfile.
# CI uses `uv sync --frozen` to install from the lockfile.
uv add pyjwt[crypto] httpx        # JWT validation
uv add authlib                    # OAuth 2.0 client
```

**C#**
```bash
dotnet add package Microsoft.AspNetCore.Authentication.JwtBearer
dotnet add package Microsoft.Identity.Web      # Azure AD (if applicable)
```

**Configuration (all stacks):**
- Store IdP settings in environment variables — never hardcode:
  - `AUTH_ISSUER` — Token issuer URL
  - `AUTH_AUDIENCE` — Expected audience claim
  - `AUTH_JWKS_URI` — JWKS endpoint (for RS256 validation)
  - `AUTH_CLIENT_ID` / `AUTH_CLIENT_SECRET` — OAuth client credentials
- Validate all config at startup — fail fast if missing.

## Step 3 — Implement auth middleware

Create middleware that runs before protected routes:

**JWT validation must check:**
1. **Signature** — Verify against JWKS (RS256) or shared secret (HS256)
2. **Expiry** — Reject expired tokens (`exp` claim)
3. **Audience** — Matches expected `AUTH_AUDIENCE`
4. **Issuer** — Matches expected `AUTH_ISSUER`

**TypeScript (Express/Fastify)**
```typescript
// src/middleware/auth.ts
export function requireAuth(requiredRoles?: string[]) {
  return async (req, res, next) => {
    // 1. Extract token from Authorization header
    // 2. Validate JWT (signature, exp, aud, iss)
    // 3. Attach user context to request
    // 4. Check roles if requiredRoles specified
  };
}
```

**Python (FastAPI)**
```python
# src/middleware/auth.py
async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    """Validate JWT and return the authenticated user."""
    # 1. Decode and validate token
    # 2. Extract user claims
    # 3. Return user context

def require_roles(*roles: str):
    """Dependency that checks the user has required roles."""
```

**C# (ASP.NET Core)**
```csharp
// Configure in Program.cs
builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.Authority = config["Auth:Issuer"];
        options.Audience = config["Auth:Audience"];
    });

// Protect endpoints with [Authorize(Roles = "admin")]
```

## Step 4 — Protect routes with authorization

Apply auth to all routes by default, then explicitly mark public routes:

- **Public routes** — login, register, health check, public API docs
- **Authenticated routes** — everything else (require valid token)
- **Role-protected routes** — admin endpoints, destructive operations

**Resource-level authorization (IDOR prevention):**
```
GET /api/v1/orders/:id → Verify order.userId === currentUser.id
```
Never rely on path parameters alone — always verify ownership in the service layer.

## Step 5 — Implement token refresh and session management

- **Access tokens:** Short-lived (5–15 minutes).
- **Refresh tokens:** Longer-lived (7–30 days), stored securely.
- **Token storage:**
  - Web apps: HttpOnly, Secure, SameSite=Strict cookies
  - SPAs: In-memory only (not localStorage)
  - Mobile: Secure storage (Keychain / KeyStore)
- **Session regeneration:** Regenerate session ID on login, logout, and privilege escalation.
- **Logout:** Invalidate refresh token server-side; clear cookies.

## Step 6 — Add audit logging

Log all auth events with structured logging:

```json
{
  "event": "auth.login.success",
  "userId": "user-123",
  "ip": "203.0.113.1",
  "userAgent": "Mozilla/5.0...",
  "timestamp": "2026-01-15T10:30:00Z"
}
```

Events to log:
- `auth.login.success` / `auth.login.failure`
- `auth.logout`
- `auth.token.refresh`
- `auth.password.change`
- `auth.role.change`
- `auth.access.denied` (unauthorized resource access attempts)

## Step 7 — Write auth tests

**Unit tests:**
- Valid token → user context extracted
- Expired token → 401
- Invalid signature → 401
- Missing token → 401
- Insufficient role → 403
- Resource ownership check → 403 for non-owner

**Integration tests:**
- Full login flow (if custom auth)
- Protected endpoint with valid/invalid/missing token
- Role-based access control
- Token refresh flow

## Step 8 — Commit auth integration

```bash
git add -A
git commit -m "feat(auth): wire <provider> authentication and authorization

- JWT validation middleware with signature, expiry, audience checks
- Role-based access control on protected endpoints
- Resource-level authorization (IDOR prevention)
- Audit logging for all auth events
- Unit and integration tests for auth flows

Closes #<issue-number>"
```
