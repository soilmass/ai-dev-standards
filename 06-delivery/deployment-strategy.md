# Deployment Strategy

Environments, promotion flow, and where things run. The hosting picks are stack decisions; the flow and the three-box rule are not.

## Environments

| Environment | Purpose | Data |
|---|---|---|
| **Local** | Development; runs the full stack with seeded data | Seeded/synthetic only |
| **Preview** | One ephemeral deploy per PR; the URL CI gates run against | Synthetic; never production data |
| **Production** | Deployed from `main` only | Real |

- No long-lived "staging" by default: preview-per-PR plus a solid pipeline covers what staging usually pretends to. Add one only when an integration genuinely can't be exercised in preview, via an ADR.
- Each environment has its own secrets and config through the boot-validated env schema (`04-build/secrets-config.md`).

## Promotion flow

1. PR opens → preview deploy is created automatically → CI gates (including the audit tiers) run against it.
2. Merge to `main` → automatic production deploy of exactly what was previewed.
3. **No manual host-side steps** — no console tweaks, no hand-applied env edits, no SSH fixes. Anything done by hand is invisible to the next deploy and will be lost or contradicted; if a manual step seems needed, it's config that belongs in the repo or the env schema.
4. Deploys are atomic and keep the previous build warm for instant rollback (`06-delivery/rollback.md`).
5. Risky features cross the deploy boundary dark, behind flags (`06-delivery/release-process.md`) — deploy ≠ release.

## The three-box hosting rule

Where things run is decided by workload shape (full rule + current picks: `00-governance/pinned-decisions.md`):

1. **Box 1 — frontend:** edge/CDN host with preview deploys.
2. **Box 2 — long-running backend:** WebSockets, cron, queues, jobs → container PaaS. Don't contort these into serverless functions.
3. **Box 3 — state:** managed database/storage with verified backups (`07-operations/backup-dr.md`).

Start with box 1 (+3) for speed; the moment a workload fights the host, move the workload to its box rather than bending the architecture.

## Standards basis

- **Continuous Delivery** (Humble & Farley) — every change is releasable through an automated, repeatable deployment pipeline; the same artifact is promoted across environments, not rebuilt. Aligns: one build previewed, then the *exact* build deployed from `main`.
- **Deployment ≠ release** (Fowler/Hodgson, *Feature Toggles*, martinfowler.com/articles/feature-toggles.html) — pushing code to production and exposing it to users are separate acts. Aligns: risky features cross the deploy boundary dark behind flags.
- **Blue-green & canary deployment** (Fowler, martinfowler.com/bliki/BlueGreenDeployment.html) — keep the prior version instantly switch-able; expose a new version to a traffic subset before full cutover. Aligns: atomic deploys keep the previous build warm; preview-per-PR is the pre-production canary surface.
- **DORA software delivery metrics** (dora.dev/guides/dora-metrics) — deployment frequency and change lead time (throughput) vs. change fail rate, rework rate, and failed-deployment recovery time (stability); the 2024–25 model added rework rate and reframed recovery time toward throughput. The atomic-deploy + instant-rollback design optimizes recovery time directly.
- **Reproducible config across environments** (12-Factor App, factor III "Config", 12factor.net) — config lives in the environment, never the code, and differs only by environment. Aligns: per-environment secrets through the boot-validated env schema; no manual host-side edits.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Confirm the change ships through the standard promotion flow (PR → preview → production) with no manual host-side steps introduced.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the preview-deploy wiring comes from connecting the repo to the host named in the stack preset; the CI workflows already target the preview URL).
