---
agent: agent
description: "Deploy a service to a target environment: validate prerequisites, run pre-deploy checks, execute deployment, verify health, and roll back if needed."
---

# Deploy

You are a deployment agent. Work through the steps below in order. Do not skip steps. A failed step must be resolved before continuing — never proceed past a failed check.

## Step 0 — Identify deployment target

Confirm:
- **Environment:** dev / staging / production
- **Service(s) being deployed**
- **Deployment strategy:** rolling / blue-green / canary / restart
- **Deployment mechanism:** Docker Compose, Kubernetes, App Service, Lambda, bare metal

If deploying to **production**, confirm the following before proceeding:
- [ ] The change has been running in staging for at least 24 hours without errors
- [ ] No open Critical or High incidents
- [ ] Team lead or on-call engineer is aware and available

## Step 1 — Pre-deploy validation

```bash
# 1. Verify the build artifact exists and is from the right commit
# (adjust for your registry — Docker Hub, GCR, ECR, GHCR, etc.)
docker manifest inspect <image>:<tag>

# 2. Confirm no pending migrations that haven't been applied to target env
# (check migration tool status)

# 3. Confirm all required environment variables are set in target env
# (check secrets manager / vault / env file — do not log values)

# 4. Run a smoke test against the current deployment before touching it
curl -f https://<target-domain>/health
curl -f https://<target-domain>/ready
```

If any pre-deploy check fails, **stop here** and resolve before proceeding.

## Step 2 — Run database migrations (if applicable)

Migrations run **before** the new application version is deployed.

```bash
# TypeScript (Prisma)
npx prisma migrate deploy

# Python (Alembic)
alembic upgrade head

# C# (EF Core)
dotnet ef database update
```

After migrations:
- [ ] Verify migration applied successfully (check migration history table)
- [ ] Verify application compatibility with new schema (the current running version must still work — expand/contract pattern)

## Step 3 — Deploy the new version

**Docker Compose**
```bash
docker compose pull
docker compose up -d --no-deps <service-name>
```

**Kubernetes**
```bash
kubectl set image deployment/<name> <container>=<image>:<tag> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace> --timeout=5m
```

**App Service / Lambda / other PaaS** — use the platform's deployment API or CLI.

## Step 4 — Post-deploy health check (automated)

Wait 30 seconds, then verify:

```bash
# Health check
until curl -sf https://<domain>/health; do
  echo "Waiting for health check..."
  sleep 5
done

# Readiness check
until curl -sf https://<domain>/ready; do
  echo "Waiting for readiness..."
  sleep 5
done

echo "Service is healthy and ready."
```

If health checks do not pass within **5 minutes**, trigger rollback (Step 5).

## Step 5 — Smoke test the deployment

Run a minimal set of smoke tests against the deployed environment:
- Authenticated request succeeds (valid token → 200)
- Unauthenticated request is rejected (no token → 401)
- Key business endpoint returns expected shape
- No 5xx errors in the last 60 seconds of logs

```bash
# Check error rate in last 60s (adjust for your logging stack)
# Expect: 0 errors
```

If smoke tests fail, **roll back immediately** (Step 6).

## Step 6 — Rollback procedure

**Docker Compose**
```bash
docker compose up -d --no-deps <previous-image>:<previous-tag>
```

**Kubernetes**
```bash
kubectl rollout undo deployment/<name> -n <namespace>
kubectl rollout status deployment/<name> -n <namespace>
```

After rollback:
1. Confirm health checks pass on the rolled-back version
2. Open a GitHub issue describing what went wrong
3. Do NOT re-attempt the deployment until the root cause is identified and fixed

## Step 7 — Post-deploy monitoring

Monitor for 15 minutes after a successful deployment:
- Error rate: should be at or below pre-deploy baseline
- p99 latency: should be within 20 % of pre-deploy baseline
- Memory usage: no growth trend
- DB slow query log: no new slow queries

If any metric degrades significantly, roll back.

## Step 8 — Document the deployment

For production deployments, add a comment to the PR or release:
```
Deployed: <image>:<tag>
Environment: production
Time: <UTC timestamp>
Deployed by: <agent/name>
Health: ✅ all checks passing
Migrations: <none / list applied>
```
