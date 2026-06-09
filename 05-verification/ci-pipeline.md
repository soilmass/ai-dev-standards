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
| SAST (CodeQL) | `04-build/static-analysis.md` |
| Dependency audit + license allowlist | `04-build/dependency-policy.md` |
| PR-size gate | `02-product/task-decomposition.md` |
| Migration-discipline guard | `06-delivery/migration-discipline.md` |
| Docs-updated check | `_spines/documentation.md` |
| Enforcement integrity (no weakened gates) | `00-governance/agent-operating-rules.md` §3 |
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

## Branch protection — the one manual step

The bootstrap cannot set host-side repository settings; do this once after the first push (Settings → Branches → add a rule for `main`, or the equivalent ruleset):

1. Require a pull request before merging (no direct pushes — mirrors the local hook).
2. Require status checks to pass, and mark **all PR jobs** required. With this preset the check names are: `Lint & format (Biome)`, `Type check (tsc, strict)`, `Unit + component tests (Vitest, a11y included)`, `Secret scan (gitleaks)`, `SAST (CodeQL)`, `PR size gate`, `Enforcement integrity`, `Dependency audit + license allowlist`, `Supply chain (SBOM + dependency review)`, `Migration discipline guard`, `Docs-updated check`, `Production build`, `Lighthouse CI (preview deploy)`. The injected `scripts/setup-branch-protection.sh` (step below) derives this list straight from `pr.yml`, so it stays correct even if the job set changes.
3. Require branches to be up to date before merging.
4. Block force pushes and deletions on `main`.
5. Do **not** allow administrators to bypass — solo means you're the admin; an escape hatch for you is an escape hatch for every agent run.

## Standards basis

- **Continuous Integration** (Fowler; Humble & Farley, *Continuous Delivery*): every change is verified by an automated build on a shared mainline; a broken build is fixed immediately, not worked around. Grounds "the pipeline IS the enforcement layer" and the rule that a flaky stage is fixed with test-level urgency.
- **Fail-fast** (Humble & Farley): order the build so the cheapest, fastest checks run first and surface failures soonest — exactly the tiered execution model (static/unit → build → preview audit) here.
- **DORA software delivery performance metrics** (dora.dev): the canonical balanced set is *deployment frequency*, *change lead time*, *change fail rate*, and *failed deployment recovery time* (the 2023 rename of MTTR), with *deployment rework rate* added as a fifth in 2024. DORA's evidence shows throughput and stability are correlated, not traded off — a fast, always-green required-check pipeline is the mechanism that lowers change-fail rate while raising deployment frequency. Required-status-checks-before-merge is how this pipeline keeps change-fail rate low; small PRs (PR-size gate) shorten change lead time.
- **Trunk-based development / branch protection** (DORA capabilities catalog): protected mainline with required checks and no admin bypass is a measured driver of delivery performance — grounds the branch-protection checklist and the no-self-bypass rule.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml + stacks/nextjs-default/ci/nightly.yml + stacks/nextjs-default/ci/release.yml
- Fallback if unenforceable: n/a — the pipeline is self-enforcing once branch protection marks every PR stage required (checklist above).

## Bootstrap
- What new-project.sh injects for this standard: the workflow files (PR, nightly, release) into `.github/workflows/` and `lighthouserc.json` at the project root, plus `scripts/setup-branch-protection.sh` which applies the required-checks ruleset via the GitHub API (derives the check list from `pr.yml`). Branch protection still requires running that one script (or the manual checklist above) after the first push — host-side settings the bootstrap can't set itself; it's linked from the bootstrap output's next-steps.
