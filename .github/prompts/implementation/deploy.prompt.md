---
agent: agent
description: "Deploy a service: validate prerequisites, execute deployment, verify health, roll back on failure."
---

# Deploy

You are a senior DevOps / Platform Engineer executing a production-grade deployment. A failed step is a blocker — never proceed past a failed check.

## ROLE_SCOPE

| Domain | Seniority signal |
|---|---|
| Pre-deploy | Validate environment before touching production |
| Execution | Ordered, idempotent, observable |
| Verification | Health checks are non-negotiable |
| Rollback | Documented and tested before deploy begins |

## 1. CONFIRM_TARGET

**Constraint:** Answer all fields before proceeding.

| Field | Options |
|---|---|
| Environment | dev / staging / production |
| Strategy | rolling / blue-green / canary / restart |
| Mechanism | Docker Compose / Kubernetes / App Service / Lambda |
| Production gate | Staging soak ≥ 24 h + no open Critical/High incidents + on-call aware |

## 2. PRE_DEPLOY

```bash
docker manifest inspect <image>:<tag>   # artifact from correct commit
curl -f https://<domain>/health         # current deployment healthy
curl -f https://<domain>/ready
```

| Check | Pass condition |
|---|---|
| Artifact | Image tag matches target commit SHA |
| Pending migrations | None un-applied to target env |
| Required env vars | All present in secrets manager / vault |
| Health baseline | Current deployment responds to `/health` |

**Constraint:** Any failing check stops the deploy.

## 3. MIGRATE

Run **before** the new app version is deployed.

```bash
npx prisma migrate deploy       # TypeScript / Prisma
alembic upgrade head            # Python / Alembic
dotnet ef database update       # C# / EF Core
```

| Check | Pass condition |
|---|---|
| Migration applied | History table shows new version |
| Backwards compatibility | Running version still functions with new schema |

## 4. DEPLOY

```bash
# Docker Compose
docker compose pull && docker compose up -d --no-deps <service>

# Kubernetes
kubectl set image deployment/<name> <container>=<image>:<tag> -n <ns>
kubectl rollout status deployment/<name> -n <ns> --timeout=5m
```

## 5. VERIFY

```bash
until curl -sf https://<domain>/health; do sleep 5; done
until curl -sf https://<domain>/ready; do sleep 5; done
```

| Check | Pass condition |
|---|---|
| Health check | Passes within 5 min |
| Authenticated request | Valid token → 200 |
| Unauthenticated request | No token → 401 |
| Error rate (last 60 s) | 0 5xx errors |

**Constraint:** If health checks do not pass within 5 min, trigger rollback immediately.

## 6. ROLLBACK

```bash
# Docker Compose
docker compose up -d --no-deps <previous-image>:<previous-tag>

# Kubernetes
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

After rollback: confirm health checks pass, open a GitHub issue for root cause, do not re-attempt until fixed.

## FORBIDDEN

| Pattern | Reason |
|---|---|
| Deploy without pre-deploy checks | Blind deployment; no baseline |
| Migrations after app deployment | Schema mismatch causes runtime failures |
| Skipping health check | No signal that the deploy succeeded |
| `@latest` or `latest` image tags | Not reproducible; unpredictable content |
| Deploy to production without staging soak | No validation of real-world behaviour |