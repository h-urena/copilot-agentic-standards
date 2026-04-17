# Project Context
<!--
  Agent memory bootstrap — populate this during project kickoff.
  Agents read this file to understand the project without needing to
  re-explore the codebase each session. Keep it up to date as the
  project evolves.
-->

## Project

- **Name**:
- **Purpose**: <!-- one sentence on what this product/service does -->
- **Owner / team**:
- **Stack(s)**: <!-- e.g. TypeScript (Next.js), Python (FastAPI), C# (gRPC worker) -->
- **Repo**:
- **Environments**: <!-- dev / staging / prod -->
- **Project board**: <!-- GitHub Project URL -->

## Architecture

- **Frontend**: <!-- framework, port, entry point -->
- **API / Backend**: <!-- framework, port, key entry point files -->
- **Data store(s)**: <!-- e.g. PostgreSQL 16 (primary), Redis 7 (cache/sessions) -->
- **Auth provider**: <!-- e.g. Auth0, Azure AD, Keycloak, self-hosted -->
- **Message broker / queue**: <!-- or "none" -->
- **Key third-party integrations**: <!-- APIs, SDKs, services -->
- **Deployment**: <!-- Docker / k8s / App Service / Lambda / etc. -->

## Repo layout

<!-- Quick map so agents know where to find things -->
```
<repo>/
  src/           # production code
  tests/         # test suites
  docs/          # architecture docs, ADRs
  .github/       # workflows, instructions, prompts
```

## Key conventions (project-specific overrides)

<!-- Document anything that diverges from or extends the base copilot instructions -->
-
-

## Environment variables

<!-- List required env vars and their purpose (never their values) -->
| Variable | Purpose | Required |
|----------|---------|----------|
| `DATABASE_URL` | Primary DB connection string | Yes |
| `AUTH_ISSUER` | JWT issuer URL | Yes |
| `AUTH_AUDIENCE` | JWT audience claim | Yes |

## Domain glossary

<!-- Short definitions for domain-specific terms an agent needs to understand correctly -->
| Term | Meaning |
|------|---------|
|      |         |

## Key decisions (ADRs)

<!-- Link or summarise the most important architectural decisions -->
| Decision | Rationale | Date |
|----------|-----------|------|
|          |           |      |

## Known gotchas

<!-- Caveats, quirks, and footguns that cost time to rediscover -->
-

## Agent notes

<!-- Insights and patterns discovered while working on this project -->
-
