# Skill: Test Generation

This skill guides agents through writing high-quality, comprehensive test suites. Load this file when asked to write tests for any code.

## Before writing a single test

1. Read the code under test completely. Identify:
   - All public entry points (functions, methods, endpoints)
   - All branching conditions (`if`, `switch`, `match`, `?:`, `??`)
   - All error paths (throws, returns error, returns null/undefined)
   - All external dependencies (DB, cache, HTTP, queue, clock, random)

2. Write a coverage plan as comments before any test code:
   ```
   // Test plan for UserService.deactivate:
   // HAPPY: deactivates an active user → marks inactive, revokes sessions
   // HAPPY: already-inactive user → no-op, returns success
   // ERROR: user not found → NotFoundError
   // ERROR: caller lacks permission → ForbiddenError
   // BOUNDARY: userId is empty string → ValidationError
   ```

3. Never write the implementation and tests in the same step — finish one, then the other.

## Test structure (all stacks)

```
Arrange  →  Act  →  Assert
```

- **Arrange**: set up the world (create fixtures, stub dependencies, seed DB)
- **Act**: call the code under test — one action per test
- **Assert**: verify one logical outcome per test (multiple `expect` calls are fine if they all assert the same thing)

## Mocking strategy

### When to use mocks
- External HTTP calls: always mock
- Email / SMS / push: always mock
- Clock (`Date.now()`, `datetime.now()`): mock when the code branches on time
- Random / UUID: mock for determinism when IDs are asserted

### When NOT to mock
- Your own database — use Testcontainers with a real engine
- Your own cache — use a real Redis container
- Business logic modules — test them directly, don't mock them in their own tests

### How to mock (by stack)

**TypeScript (Vitest)**
```typescript
import { vi, describe, it, expect, beforeEach } from 'vitest';
import { sendEmail } from '../email/email.service';

vi.mock('../email/email.service');

const mockSendEmail = vi.mocked(sendEmail);

beforeEach(() => {
  mockSendEmail.mockResolvedValue(undefined);
});

it('sends a welcome email after registration', async () => {
  await registerUser({ email: 'alice@example.com', password: 'hunter2' });
  expect(mockSendEmail).toHaveBeenCalledOnce();
  expect(mockSendEmail).toHaveBeenCalledWith(
    expect.objectContaining({ to: 'alice@example.com', template: 'welcome' })
  );
});
```

**Python (pytest + unittest.mock)**
```python
from unittest.mock import AsyncMock, patch
import pytest

@pytest.mark.asyncio
async def test_sends_welcome_email_after_registration():
    with patch("app.email.send_email", new_callable=AsyncMock) as mock_send:
        await register_user(email="alice@example.com", password="hunter2")
        mock_send.assert_called_once()
        call_kwargs = mock_send.call_args.kwargs
        assert call_kwargs["to"] == "alice@example.com"
        assert call_kwargs["template"] == "welcome"
```

**C# (xUnit + Moq / NSubstitute)**
```csharp
[Fact]
public async Task RegisterUser_SendsWelcomeEmail()
{
    var emailService = Substitute.For<IEmailService>();
    var sut = new UserService(emailService);

    await sut.RegisterAsync(new RegisterRequest("alice@example.com", "hunter2"));

    await emailService.Received(1).SendAsync(
        Arg.Is<Email>(e => e.To == "alice@example.com" && e.Template == "welcome"),
        Arg.Any<CancellationToken>()
    );
}
```

## Integration test template

Use real infrastructure. Use Testcontainers to start a disposable DB.

```typescript
// TypeScript — Vitest + Testcontainers
import { PostgreSqlContainer } from '@testcontainers/postgresql';

let container: StartedPostgreSqlContainer;
let db: PrismaClient;

beforeAll(async () => {
  container = await new PostgreSqlContainer().start();
  db = new PrismaClient({ datasourceUrl: container.getConnectionUri() });
  await db.$executeRaw`-- run migrations`;
});

afterAll(async () => {
  await db.$disconnect();
  await container.stop();
});

beforeEach(async () => {
  await db.$executeRaw`TRUNCATE users, sessions CASCADE`;
});
```

## Coverage checklist (review before marking tests done)

- [ ] All happy paths covered
- [ ] All error branches covered
- [ ] All boundary values covered (empty, null, zero, max)
- [ ] No shared mutable state between tests
- [ ] No `sleep` / `Thread.Sleep` calls
- [ ] No vacuous assertions (`expect(true).toBe(true)`)
- [ ] Test names describe behaviour, not implementation
- [ ] No test marked as skipped without a linked issue
