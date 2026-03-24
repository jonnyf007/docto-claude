# Docto — Shared Claude Context

Docto is an Australian/New Zealand healthcare telemedicine platform for online video consultations, appointment booking, and patient/doctor/referrer management.

## Repos

| Repo | Purpose | Stack | Local Port |
|---|---|---|---|
| `docto-api` | Backend REST API | Node.js/Express, MongoDB, Redis | 6003 |
| `docto-app` | Admin/internal frontend | React (CRA + craco) | 6002 (HTTPS) |
| `docto-nextjs` | Public patient-facing site | Next.js 14, SSR | 3000 |
| `docto-claude` | Shared Claude context & skills | — | — |

## Git Workflow

```
feature/<ticket-or-description>  →  staging  →  qat  →  production
```

- Always branch from `staging`
- All repos deploy via **GitHub Actions** on push to `staging`, `qat`, or `production` branches
- **Exception:** `docto-api/scheduled_tasks/` Lambdas deploy via `./deploy-code.sh <env>` (not GH Actions)
- PR back to `main` after production confirmed

## Trello Workflow

1. PO creates card in Trello with title + description
2. Dev picks up card → creates feature branch → moves card to "In Progress"
3. Deploy to staging → QAT testing → production
4. Move card to "Done"

## Environments

| Env | Notes |
|---|---|
| staging | Dev/test — emails redirected via `SEND_EMAILS_TO` env var |
| qat | QA team testing |
| production | Live — `https://app.docto.com.au` |

Lambda env var prefix: `STG_`, `QAT_`, `PROD_`.

## Available Skills

- `/ticket [trello-url]` — fetch card, identify tasks, create branch
- `/deploy [staging|qat|production]` — push to env branch or run deploy-code.sh for lambdas
- `/pr` — generate PR title/description and run `gh pr create`
- `/update-context` — suggest edits to CLAUDE.md files based on recent commits
- `/web-vitals [audit|instrument|deploy-check]` — Web Core Vitals expert for docto-nextjs: audit codebase, add web-vitals tracking, run Lighthouse

## Shared Conventions

- No trailing summaries after completing work — just do it
- Keep controllers thin; all logic in services
- Throw `new ApiError(httpStatus.XXX, 'msg')` for errors — never return error objects directly
- MongoDB Atlas (not local) for staging/qat/production; local Docker for dev
- AWS region: `ap-southeast-2` (Sydney)
