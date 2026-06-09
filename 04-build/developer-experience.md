# Developer Experience

The inner loop — clone, run, change, see the result — is the multiplier on every other standard: a slow or fragile setup tax is paid on every task, and for a solo+AI workflow the agent pays it too. This doc makes the environment reproducible and the loop fast, so "works on my machine" is a guarantee, not a hope.

## Reproducible environment

1. **One command to a running app.** A fresh clone reaches a running dev server in a single documented command path (the bootstrap output's next-steps), not a scavenger hunt — `install → bring up local services → migrate → seed → dev`. Every manual prerequisite is either scripted or removed.
2. **The environment is pinned and containerized, not described.** Local services run from a committed `docker-compose.yml` with **pinned images** (calibration CAL-D14), and the editor/runtime is captured in a committed `.devcontainer/devcontainer.json` pinned to the same Node line as CI (CAL-D01). A README paragraph telling you to "install Postgres 17" drifts; a pinned compose file doesn't.
3. **Dev/prod parity.** Local backing services match production in kind and major version (Twelve-Factor X) — the same database engine and major, so a query that works locally works in prod. Production still uses the managed service (`06-delivery/deployment-strategy.md`); local just mirrors its shape.

## A fast, trustworthy inner loop

4. **The loop is fast and incremental.** Hot-reload for the app, watch-mode + the unit tier for tests; the per-change feedback a developer (or agent) waits on is seconds, not a full build. Slow feedback is a defect to fix, like a flaky test.
5. **Seed data is a committed, idempotent script, never a manual ritual.** `pnpm db:seed` populates a representative-but-minimal dataset (enough to exercise the core loop), is safe to re-run (upsert/conflict-do-nothing), and **never targets production** — it writes rows. A shared SQL dump passed around in chat is not seed data.
6. **The feedback loop is the metric.** DORA/SPACE research ties developer throughput to fast feedback and low friction; treat onboarding-to-running time and inner-loop latency as numbers to keep low, and a regression in either as worth fixing.

## Standards basis

- **The Twelve-Factor App** (12factor.net) — **X. Dev/prod parity** (keep development, staging, and production as similar as possible, same backing-service type and version) is the basis for rules 2–3; **III. Config in the environment** ties the local `DATABASE_URL` to the same boot-validated schema as prod (`04-build/secrets-config.md`).
- **Development Containers specification** (containers.dev) — a committed, pinned, reproducible dev environment as code; the basis for rule 2's `devcontainer.json`.
- **DORA / SPACE / DX Core 4** (dora.dev; the SPACE framework, Forsgren et al.; DX Core 4) — fast feedback loops and low friction are measured drivers of delivery performance and developer effectiveness; grounds rule 6 (treat inner-loop latency and onboarding time as metrics) and rule 4.
- Pairs with `04-build/testing-strategy.md` (the fast unit tier is the inner-loop test surface) and `06-delivery/deployment-strategy.md` (prod uses the managed equivalent of the local compose services).

## Enforcement
- Mechanism: none-possible
- Config: stacks/nextjs-default/project-config/.devcontainer/devcontainer.example.json + docker-compose.example.yml + db/seed.example.ts (and the nextjs-container equivalents)
- Fallback if unenforceable: If a change affects local setup or onboarding, the one-command bootstrap still works — the pinned devcontainer/compose and the idempotent seed script are updated in the same change, and dev still mirrors prod's backing-service major.

## Bootstrap
- What new-project.sh injects for this standard: `.devcontainer/devcontainer.json`, `docker-compose.yml` (pinned local Postgres + adminer), and the idempotent `db/seed.ts` (Prisma: `prisma/seed.ts`) with a `db:seed` script — a fresh clone is one `docker compose up -d` + install + migrate + seed from a running app.
