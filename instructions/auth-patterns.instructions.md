---
applyTo: "**"
---

# Authentication & authorization Patterns

These rules apply to any service that manages identity, sessions, tokens, or access control.

## Prefer delegated identity management

- Use a proven identity provider (Auth0, Azure AD B2C/Entra, AWS Cognito, Keycloak, Okta) rather than building auth from scratch.
- Implement OAuth 2.0 / OIDC flows — do not invent custom token formats.
- The identity provider owns `login`, `logout`, `MFA`, `password reset`, and `account lockout`.
- Your service validates tokens; it does not issue them (unless you are building an auth service).

## JWT validation

Validate all three of these on every request — do not trust a token without checking all:

1. **Signature** — verify against the provider's public key (JWKS endpoint)
2. **Expiry** — reject tokens where `exp` is in the past
3. **Claims** — verify `aud` (your service), `iss` (your provider)

```python
# Python — jose / PyJWT
payload = jwt.decode(token, public_key, algorithms=["RS256"],
                     audience="my-api", issuer="https://my-idp.example.com")
```

```ts
// TypeScript — jose
const { payload } = await jwtVerify(token, JWKS, {
  audience: 'my-api',
  issuer: 'https://my-idp.example.com',
});
// Never use jwt.decode() without verification
```

```csharp
// C# — Microsoft.AspNetCore.Authentication.JwtBearer
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options => {
        options.Authority = "https://my-idp.example.com";
        options.Audience = "my-api";
    });
```

## Token storage

| Location | Risk | Verdict |
|----------|------|---------|
| `localStorage` | XSS can steal token | **Never** for sensitive tokens |
| `sessionStorage` | XSS can steal token | **Never** for sensitive tokens |
| `HttpOnly; Secure; SameSite=Strict` cookie | CSRF mitigated by SameSite | **Preferred** for SSR / BFF |
| Memory (JS variable) | Lost on refresh; XSS risk if exposed | Acceptable for short-lived access tokens in SPA |

- Access tokens: short-lived (5–15 minutes).
- Refresh tokens: longer-lived; stored `HttpOnly` cookie or server-side only. Rotate on every use.

## Session security

- Session IDs must be cryptographically random (≥ 128 bits).
- Regenerate the session ID on any privilege escalation (login, sudo, role change).
- Enforce both an idle timeout and an absolute session timeout.
- CSRF protection for cookie-based sessions:
  - `SameSite=Strict` or `SameSite=Lax` cookies mitigate most CSRF.
  - Add a CSRF token for state-changing requests when using `SameSite=None`.

## authorization

- Enforce authorization at the **service / use-case layer**, not only at the controller/route layer.
- Use RBAC (roles → permissions) or ABAC (attribute-based) — not ad-hoc `if user.isAdmin` conditions scattered through code.
- Principle of least privilege: grant only what the operation requires.
- **Resource-level authorization**: after authenticating a request, verify the caller owns or has explicit permission on the **specific resource** being accessed. This prevents IDOR (Insecure Direct Object Reference).

```python
# Python — always check ownership
order = db.query(Order).filter_by(id=order_id).first()
if order is None or order.user_id != current_user.id:
    raise HTTPException(status_code=403)
```

```ts
// TypeScript — always check ownership
const order = await orderRepo.findById(orderId);
if (!order || order.userId !== ctx.user.id) throw new ForbiddenError();
```

```csharp
// C# — IAuthorizationService for resource-based checks
var result = await authService.AuthorizeAsync(user, order, "OwnerPolicy");
if (!result.Succeeded) return Forbid();
```

## Password management (if handling locally)

- **Never** store plaintext passwords.
- Hash with `bcrypt` (cost ≥ 12), `Argon2id`, or `scrypt`. Do not use MD5, SHA-1, or unsalted SHA-256.
- Enforce minimum password length ≥ 12 characters.
- Check new passwords against the HaveIBeenPwned API (k-anonymity model) at signup and password change.
- Rate-limit login attempts per IP and per account. Implement progressive lockout.

Stack defaults:
- Python: `passlib[bcrypt]`
- TypeScript: `bcryptjs` or `argon2`
- C#: `Microsoft.AspNetCore.Identity` (built-in bcrypt via `PasswordHasher<T>`)

## Secrets and credentials

- **Never hardcode** API keys, tokens, connection strings, or passwords in source code.
- Load from environment variables at startup, validated with:
  - TypeScript: `t3-env` / Zod
  - Python: `pydantic-settings`
  - C#: `IOptions<T>` with `ValidateOnStart()`
- Use a secrets manager for production: HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, GCP Secret Manager.
- Rotate secrets on a schedule and immediately on suspected compromise.
- Secrets must **never appear** in logs, error responses, or API payloads.

## Audit logging

Log all authentication-relevant events with the following fields:
- User ID (or `anonymous`)
- IP address
- User-agent
- Timestamp (UTC, ISO 8601)
- Event type: `login_success`, `login_failure`, `logout`, `token_refresh`, `password_change`, `mfa_challenge`, `account_locked`
- Outcome and reason on failure

Do **not** log passwords, raw tokens, session IDs, or any PII beyond what is strictly necessary for the audit.
