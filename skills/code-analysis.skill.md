# Skill: Code Analysis

This skill guides agents through deep, systematic code analysis. Load this file when performing a thorough review of a codebase, module, or PR.

## Analysis phases (execute in order)

### Phase 1 — Map the surface area

Before reading any logic:
1. List all public entry points: API routes, public methods, exported functions, event handlers.
2. List all external dependencies: databases, caches, HTTP clients, queues, file system.
3. Identify the data flow: how does data enter (HTTP body, env var, DB read), how does it exit (HTTP response, DB write, queue publish)?
4. Identify the trust boundary: which inputs come from untrusted callers?

### Phase 2 — Correctness analysis

For each code path, verify:

**Data integrity**
- Is every external input validated at the trust boundary before use?
- Are type assertions or casts safe? Could they panic/throw at runtime?
- Are null/undefined dereferences possible?
- Are integer overflows or precision losses possible (floating point for money)?

**Concurrency**
- Are shared mutable objects accessed from multiple goroutines/threads/coroutines without synchronisation?
- Could `async` functions run concurrently when they must be sequential?
- Are database operations that must be atomic wrapped in a transaction?

**Error handling**
- Are all error paths handled explicitly? No empty `catch` blocks.
- Are transient errors retried? Are non-transient errors NOT retried?
- Are resource handles (file handles, DB connections, HTTP clients) closed in all exit paths?

### Phase 3 — Security analysis

Run through the OWASP Top 10 mentally for each module:

| Check | Pattern to look for |
|-------|-------------------|
| Injection | String-concatenated SQL, shell commands, template expressions |
| Broken auth | Missing auth checks, insecure token storage, predictable IDs |
| Sensitive data | Secrets/PII in logs, error messages, URLs, or Git |
| Broken access control | IDOR — resource ownership not checked before return |
| Security misconfiguration | CORS `*`, debug mode in prod, permissive headers |
| XSS | `dangerouslySetInnerHTML`, `innerHTML`, `MarkupString` with user input |
| Deserialization | `eval`, `pickle.loads`, `BinaryFormatter`, `JSON.parse` without schema |
| Logging PII | Email, name, card, SSN in log statements |

### Phase 4 — Performance analysis

- Are there N+1 query patterns? (Loop that executes a query per iteration)
- Are expensive operations (regex compile, DB connection) being performed inside a hot loop?
- Are large result sets fetched when only a subset is needed? (missing `LIMIT`, missing field projection)
- Is caching applied where the data is read-heavy and write-infrequent?
- Is pagination enforced on list endpoints?

### Phase 5 — Maintainability analysis

- **Coupling**: does this module depend on internal implementation details of another? Should be depending on interfaces.
- **Cohesion**: does each class/module have a single clear responsibility?
- **Duplication**: is logic copy-pasted that should be shared? Shared how — utility function, base class, or separate service?
- **Naming**: do names communicate intent? Is anything abbreviated to the point of ambiguity?
- **Complexity**: are there functions with cyclomatic complexity > 10? They should be split.
- **Dead code**: are there unreachable branches, unused variables, unused imports?

## Finding severity classification

| Severity | Definition | Action |
|----------|-----------|--------|
| **Critical** | Security vulnerability, data loss risk, crash in production | Block PR — fix before merge |
| **High** | Correctness bug affecting real users, missing error handling | Block PR — fix before merge |
| **Medium** | Performance issue, architectural concern, debt that compounds | Comment — must be tracked as an issue |
| **Low** | Style, naming, minor improvement | Comment — author's discretion |

## Output format for each finding

```
[CRITICAL/HIGH/MEDIUM/LOW] <file>:<line>
Problem: <concise description of what is wrong>
Risk: <what bad thing happens as a result>
Fix: <specific change to make>
```

## Do not flag

- Style differences that are covered by the formatter (Prettier, Black, CSharpier) — the linter handles this
- Personal preferences with no correctness or security impact
- Speculative performance improvements without evidence of a bottleneck
