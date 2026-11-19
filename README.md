# Platform CI/CD (scaffold)

Local-only scaffold. No secrets, no network writes, no git init. Nothing here deploys
until an app repo opts in via the caller workflow.

## Architecture

| Layer | Target | How it ships |
|---|---|---|
| Frontends | Vercel | Native Git integration. Actions do **not** need a Vercel token. |
| Edge/API | Cloudflare Workers | `cloudflare/wrangler-action@v3` + `wrangler deploy`. |
| Backends (no free tier) | GHCR + Coolify (OCI server) | Multi-arch image pushed to GHCR, Trivy scan, Coolify webhook, health poll. |
| Database | Supabase Cloud `fleet-core` (`sonhltqafwgxuntydysv`, `ap-south-1`) | `supabase db push` via a `kind: supabase` call. |
| Auth | Clerk `fleet-core` (`app_3MK6cjNxpSMW4FvPDYgnfcCDBnU`, dev instance) | Keys injected as repo secrets. |

`deploy.yml` is a reusable workflow (`workflow_call`). It has one blocking `verify`
job, `if:`-guarded deploy jobs, an optional `migrate-supabase` job, and a final
`health` gate. Concurrency is `deploy-<app>-<ref>` with cancellation.

## Calling it from an app repo

Copy `.github/workflows/caller-example.yml` to the app's
`.github/workflows/deploy.yml` (or use `scripts/bootstrap-repo.sh`). The whole
call is:

```yaml
jobs:
  deploy:
    uses: shrijit37/platform/.github/workflows/deploy.yml@main
    with:
      kind: container   # vercel | worker | container | supabase
      app: my-app
    secrets: inherit
```

Set `vars.APP_URL` on the repo to the public base URL; the health gate appends
`health-path` (default `/health`). For a Supabase-only call set
`test-command: "true"` if the repo has no test suite. Migrations run before
container/worker deploys via `needs:`; if an app needs both, trigger the
`kind: supabase` call first (e.g. a first job in the caller, with the app job
`needs:` it).

## Secrets (per kind)

Set with `gh secret set <NAME>` in the **app repo**. Never commit values.

| Kind | Required secrets | Optional |
|---|---|---|
| all | — | `CLERK_SECRET_KEY`, `CLERK_PUBLISHABLE_KEY` for builds needing auth |
| `vercel` | — (native Git integration) | `VERCEL_TOKEN` + `vars` project name only if using CLI deploy |
| `worker` | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` | — |
| `container` | `COOLIFY_WEBHOOK`, `COOLIFY_TOKEN` | `DOTENV_PRIVATE_KEY_PRODUCTION` |
| `supabase` | `SUPABASE_PROJECT_REF`, `SUPABASE_DB_PASSWORD` | — |

Already set across the 13 fleet repos: `SUPABASE_PROJECT_REF`,
`SUPABASE_DB_PASSWORD`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`,
`SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SERVICE_ROLE_KEY`,
`SUPABASE_SECRET_KEY`, `CLERK_PUBLISHABLE_KEY`,
`NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`.

`SUPABASE_ACCESS_TOKEN` is **not** needed: migrations run through the Supavisor
pooler (`aws-0-ap-south-1.pooler.supabase.com:6543`) with the DB password alone.
This is required because direct `db.<ref>.supabase.co:5432` connections time out
from GitHub-hosted runners.

All Clerk secrets are now set across the 13 fleet repos and verified live:
`CLERK_SECRET_KEY`, `CLERK_PUBLISHABLE_KEY`, `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`,
`CLERK_API_URL` (`https://api.clerk.com`) and `CLERK_JWKS_URL`
(`https://careful-goblin-2052.clerk.accounts.dev/.well-known/jwks.json`).
Clerk frontend domain: `careful-goblin-2052.clerk.accounts.dev`.
`GITHUB_TOKEN` is provided automatically for GHCR push.

`lib/auth/verify-token.ts` is the shared dual-run helper: it accepts Clerk tokens
first, then legacy Supabase GoTrue tokens, so apps can migrate one at a time.
Copy it into each app's `src/lib/` until the platform repo is published as a
package.

## Schema ownership

All fleet schemas are consolidated in `supabase/migrations/` here with unique
version numbers (`0001_llmbridge` … `0011_rehearse_namespace`). The original
per-repo files were all named `0001_fleet_schema.sql`, which made Supabase
record a single version and skip the other nine apps. **Do not push migrations
from individual app repos** — push from this directory:

```bash
supabase db push --remote "postgresql://postgres.sonhltqafwgxuntydysv:<password>@aws-0-ap-south-1.pooler.supabase.com:6543/postgres" --include-all --yes
```

Four table names collided across apps and were namespaced in the central schema
and the corresponding app code: `vidyaai_users`, `vidyaai_audit_logs`,
`vidyaai_boards`, `triptribe_users`, `rehearse_organizations`,
`rehearse_organization_members`. `users`, `audit_logs` and `boards` remain with
Rehearse/dayboard respectively. Also fixed a latent bug in vidyaai's source
migration (it indexed `role` without creating the column).

## Manual dashboard step (Supabase CLI cannot do this)

`supabase config push` does **not** apply `[auth.third_party.clerk]` to hosted
projects (supabase/cli#4407). The config file is kept here for local use, but
you must register `careful-goblin-2052.clerk.accounts.dev` in the Supabase
dashboard under **Authentication → Third-Party Auth → Clerk**, then complete
Clerk's "Connect with Supabase" flow.

## 5-phase migration order

1. **Inventory** — confirm `config/apps.yaml` kind guesses; set `vars.APP_URL` per repo.
2. **Foundation** — provision the secrets above; confirm Supabase/Clerk apps and GHCR access.
3. **Data + auth first** — run `kind: supabase` migrations, then point apps at Clerk dev keys.
4. **Frontends** — switch each Vercel repo to native Git integration; retire old deploy steps.
5. **Workers then containers** — cut over Workers via wrangler, then containers via GHCR+Coolify; watch health gates.

Flip `status: candidate` -> `active` in `config/apps.yaml` as each app completes phase 4/5.

## Rollback

- **Vercel:** revert the triggering commit, or promote the previous deployment in Vercel.
- **Worker:** `wrangler deployments list` then `wrangler rollback` to the last good SHA.
- **Container:** re-POST the Coolify webhook with the previous image tag/SHA (both are in GHCR), then re-run the health poll.
- **Supabase:** restore the migration with a new `supabase db push` / PITR restore — never edit applied migration files.

## Bootstrap helper

```bash
./scripts/bootstrap-repo.sh <repo-path> <app-name> [kind]
```

Writes the caller workflow only (idempotent, refuses to overwrite a different
existing file) and prints the exact `gh secret set` commands. If
`~/.config/platform/secrets.env` exists it prints commands that source it; the
script never prints secret values. It does not commit or push.
