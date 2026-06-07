# CI Pipeline

The pipeline **is** the enforcement layer: every standard that can be checked mechanically is checked here, and a rule without a pipeline stage is a suggestion. This doc pins the required stages and execution model; the preset's workflow files are the executable form.

## Required stages

### On every PR

| Stage | What it gates |
|---|---|
| Lint + format | `04-build/coding-standards.md` |
| Type check | strict-mode typing (stack ADR) |
| Unit + component tests (accessibility checks included in unit tier) | `04-build/testing-strategy.md`, `05-verification/a11y-perf-gates.md` |
| Coverage gate | erosion floor per testing strategy |
| Secret scan (full history) | `04-build/secrets-config.md` |
| Dependency audit + license allowlist | `04-build/dependency-policy.md` |
| PR-size gate | `02-product/task-decomposition.md` |
| Migration-discipline guard | `06-delivery/migration-discipline.md` |
| Docs-updated check | `_spines/documentation.md` |
| Production build (env schema boot-validated) | the app actually builds |
| Lighthouse CI on the preview deploy | `05-verification/a11y-perf-gates.md` |

### Nightly / pre-deploy

| Stage | What it gates |
|---|---|
| Full E2E suite | critical journeys (`04-build/testing-strategy.md`) |
| Visual regression | unintended UI drift |
| Backup restore verification | `07-operations/backup-dr.md` |

A production deploy never proceeds without a green run of the nightly tier (triggered manually pre-deploy if the schedule hasn't covered the latest commit).

## Execution model

**Sequential gating with parallel execution within each tier; fail fast.**

1. **Tier 1 (parallel):** all static + unit-level checks — lint, types, unit/component tests, secret scan, PR-size, deps, migration guard, docs check. Cheapest checks surface failures first.
2. **Tier 2 (after tier 1):** production build. No point building what doesn't pass tier 1.
3. **Tier 3 (after tier 2):** Lighthouse against the preview deploy — needs a deployed artifact.

## Rules about the pipeline itself

- All PR stages are **required checks** in branch protection; merging with a red or skipped required check is not possible, for anyone.
- Pipeline definitions are on the agent never-touch list when the motive is making a failing check pass (`00-governance/agent-operating-rules.md` §3). Pipeline *improvements* arrive as their own reviewed PR.
- A flaky stage is fixed with the same urgency as a flaky test — retry-until-green normalizes ignoring the gate.
- Stage list changes here and workflow file changes ship in the same commit (no drift between doc and config).

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml + stacks/nextjs-default/ci/nightly.yml
- Fallback if unenforceable: n/a — the pipeline is self-enforcing once branch protection marks every PR stage required.

## Bootstrap
- What new-project.sh injects for this standard: both workflow files into `.github/workflows/` and `lighthouserc.json` at the project root. Marking the jobs as required branch-protection checks is the one manual step, called out in the bootstrap output's next-steps.
