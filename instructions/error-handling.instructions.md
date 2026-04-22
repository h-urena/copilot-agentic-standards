---
applyTo: "**"
---

# Error Handling Standards

These rules define the universal philosophy for errors across all stacks. Stack-specific syntax is in the stack instructions.

## Two categories of errors

| Category | Definition | How to handle |
|----------|-----------|--------------|
| **Domain errors** | Expected conditions the business logic must handle: "user not found", "payment declined", "quota exceeded" | Model explicitly in the return type — never throw |
| **Exceptional errors** | Unexpected failures the code cannot meaningfully recover from: DB connection lost, out of memory, programming bug | Throw / raise — let them propagate to the top-level handler |

Never use exceptions for control flow. Never use return values to signal exceptions.

## Result type pattern

For domain errors, return a `Result<T, E>` instead of throwing:

```typescript
// TypeScript — neverthrow
import { ok, err, Result } from 'neverthrow';

async function findUser(id: string): Promise<Result<User, NotFoundError>> {
  const user = await db.users.findUnique({ where: { id } });
  if (!user) return err(new NotFoundError(`User ${id} not found`));
  return ok(user);
}

// Caller is forced to handle the error case
const result = await findUser(userId);
if (result.isErr()) {
  return res.status(404).json({ error: result.error.toJSON() });
}
const user = result.value; // typed, safe
```

```python
# Python — use dataclasses or a Result library (returns, result)
from dataclasses import dataclass
from typing import Union

@dataclass
class NotFoundError:
    message: str

async def find_user(user_id: str) -> Union[User, NotFoundError]:
    user = await db.users.get(user_id)
    return user if user else NotFoundError(f"User {user_id} not found")
```

```csharp
// C# — custom Result<T, E> or use FluentResults / ErrorOr
public async Task<Result<User, NotFoundError>> FindUserAsync(Guid id, CancellationToken ct)
{
    var user = await db.Users.FindAsync(id, ct);
    return user is null
        ? Result.Fail(new NotFoundError($"User {id} not found"))
        : Result.Ok(user);
}
```

## Structured error codes

Every domain error must have:
- A machine-readable `code` (SCREAMING_SNAKE_CASE): `USER_NOT_FOUND`, `PAYMENT_DECLINED`
- A human-readable `message` (never expose internal detail)
- An optional `details` array for field-level validation errors

HTTP error response shape (all stacks):
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request body is invalid.",
    "details": [
      { "field": "email", "message": "must be a valid email address" }
    ]
  }
}
```

Map domain error codes to HTTP status codes in one central place (a middleware or exception filter) — never in individual handlers.

## Retry policy

Retry only **transient** errors (network timeouts, HTTP 429, HTTP 503). Never retry:
- `4xx` responses (except 429)
- Business rule violations
- Validation errors

Retry strategy: **exponential backoff with jitter**
- Base delay: 100 ms
- Max delay: 30 s
- Max attempts: 3
- Jitter: ±20 % of the computed delay

```typescript
// TypeScript — use `p-retry` or `cockatiel`
import retry from 'p-retry';
const result = await retry(() => callExternalApi(), { retries: 3 });
```

```python
# Python — use `tenacity`
from tenacity import retry, stop_after_attempt, wait_exponential
@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=0.1, max=30))
async def call_external_api(): ...
```

```csharp
// C# — use Polly
var pipeline = new ResiliencePipelineBuilder()
    .AddRetry(new RetryStrategyOptions { MaxRetryAttempts = 3, BackoffType = DelayBackoffType.Exponential })
    .Build();
```

## Circuit breaker

Wrap calls to every external dependency (third-party APIs, downstream services) in a circuit breaker. The breaker opens when:
- Error rate exceeds 50 % over a 10-second window
- Or consecutive failure count exceeds 5

When the circuit is open: fail fast (return a cached/degraded response or an explicit error) rather than queuing calls that will time out.

## Never swallow errors

```typescript
// ❌ Silent failure — bugs become invisible
try {
  await doThing();
} catch {
  // do nothing
}

// ✅ Log and re-raise or convert to domain error
try {
  await doThing();
} catch (error: unknown) {
  logger.error({ error }, 'doThing failed unexpectedly');
  throw error;
}
```

## Top-level error handler

Every service must have a single top-level error handler that:
1. Catches all unhandled exceptions
2. Logs the full error with stack trace at `ERROR` level
3. Returns a generic `500` response with a `INTERNAL_SERVER_ERROR` code — never the raw message
4. Does NOT expose stack traces, file paths, or internal identifiers to callers

## Fail fast on startup

Validate all required configuration (env vars, secrets) at process start. If any required value is missing:
- Log the missing variable name at `ERROR`
- Exit with code `1`

Never let a service start in a partially-configured state that causes errors at runtime.
