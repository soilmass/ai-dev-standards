# ai-dev-standards

A reusable, project-agnostic **standards library** for a solo developer working with AI coding agents. It bootstraps and governs any full-stack web project: every standard ships with its **enforcement mechanism** and **bootstrap hook** co-located, so this library is the only meta-tooling needed to start and run a project.

## The law: GLOBAL = RULES; PROJECT = CHOICES

The suite separates two things cleanly:

- **Global standards** (`00`–`08`, `_spines/`) — project-agnostic *rules and templates*. The source of truth. No framework names, no versions, no project-specific values. The single sanctioned exception is [`00-governance/pinned-decisions.md`](00-governance/pinned-decisions.md), which documents the standing tool recommendations as defaults + deviation rules (and the governance guardrails in [`agent-operating-rules.md`](00-governance/agent-operating-rules.md) that name the tools they ban or default).
- **Stack presets** (`stacks/`) — per-stack *choices and configs*. Where decisions and real config files live. If a value is a *choice* rather than a *rule*, it belongs here.

When you're unsure where something goes: would it still be true if you switched frameworks? Yes → global. No → preset.

## Bootstrap a new project

```bash
./scripts/new-project.sh <target-directory> [stack-preset]   # default preset: nextjs-default
```

This:

1. Assembles the project's `CLAUDE.md` from [`01-context/CLAUDE.template.md`](01-context/CLAUDE.template.md) + the preset's `CLAUDE.partial.md` (you fill the `<ANGLE_BRACKET>` blanks afterward);
2. Copies the preset's known-good configs into place: lint config, CI workflows, git hooks, `dependabot.yml`, the boot-validated env schema (`env.schema.ts`, from `env.schema.example`), and the recursive `project-config/**` payload — tool configs (test runner, browser tests, ORM), test scaffolding (`tests/setup.ts`, the network-mock server + handlers, example unit/e2e/visual tests), `instrumentation.ts` (boot-time env validation), the `db/schema.ts` starter, `.gitignore`, and `.gitattributes`;
3. Drops in the working templates (ADR, glossary, architecture map, spec, threat model, incident runbook, `docs/slos.md`, `docs/debt-log.md`) under `docs/`, the GitHub community-health set (`.github/CODEOWNERS`, `SECURITY.md`, `CONTRIBUTING.md`, `ISSUE_TEMPLATE/`), and two host-side helper scripts — `scripts/setup-branch-protection.sh` (branch + tag protection + required signatures) and `scripts/configure-signing.sh` (commit/tag signing).

It is idempotent (re-running refuses to clobber files you've edited) and prints everything it did. That's the whole bootstrap — no other meta-tooling required.

## The four-test quality bar

Every standard in this library must pass four tests, tracked live in [`00-governance/completeness-matrix.md`](00-governance/completeness-matrix.md):

| Test | Meaning |
|---|---|
| **Articulated** | The rule is written down, concretely, in a layer doc. |
| **Templated** | Where a fill-in artifact is the deliverable, a `*.template.md` exists. |
| **Enforced** | A mechanism (lint rule, CI job, git hook, runtime check) catches violations — or the doc declares `none-possible` and contributes a fallback line to the AI self-review checklist. |
| **Bootstrappable** | `new-project.sh` injects the standard's config/template into new projects, or the doc states "nothing — reference only". |

Every layer doc (`02`–`08`, `_spines/`) ends with an **Enforcement / Bootstrap footer** declaring how it satisfies the last two tests; [`scripts/audit-completeness.sh`](scripts/audit-completeness.sh) verifies no doc is missing it.

## Table of contents

| Layer | Contents |
|---|---|
| [`00-governance/`](00-governance/) | [standards-lifecycle](00-governance/standards-lifecycle.md) · [agent-operating-rules](00-governance/agent-operating-rules.md) · [pinned-decisions](00-governance/pinned-decisions.md) · [repo-operating-model](00-governance/repo-operating-model.md) · [completeness-matrix](00-governance/completeness-matrix.md) · [calibration](00-governance/calibration.md) · [flow-back-log](00-governance/flow-back-log.md) |
| [`01-context/`](01-context/) | [CLAUDE.template](01-context/CLAUDE.template.md) · [adr.template](01-context/adr.template.md) · [glossary.template](01-context/glossary.template.md) · [architecture-map.template](01-context/architecture-map.template.md) |
| [`02-product/`](02-product/) | [spec.template](02-product/spec.template.md) · [task-decomposition](02-product/task-decomposition.md) · [acceptance-criteria](02-product/acceptance-criteria.md) · [definition-of-ready-done](02-product/definition-of-ready-done.md) |
| [`03-design/`](03-design/) | [architecture-standards](03-design/architecture-standards.md) · [data-modeling](03-design/data-modeling.md) · [api-contract-design](03-design/api-contract-design.md) · [api-evolution](03-design/api-evolution.md) · [rate-limiting-abuse](03-design/rate-limiting-abuse.md) · [ui-design-system](03-design/ui-design-system.md) · [ui-accessibility-patterns](03-design/ui-accessibility-patterns.md) · [threat-model.template](03-design/threat-model.template.md) · [threat-modeling](03-design/threat-modeling.md) · [data-privacy](03-design/data-privacy.md) |
| [`04-build/`](04-build/) | [coding-standards](04-build/coding-standards.md) · [git-standards](04-build/git-standards.md) · [testing-strategy](04-build/testing-strategy.md) · [dependency-policy](04-build/dependency-policy.md) · [supply-chain](04-build/supply-chain.md) · [static-analysis](04-build/static-analysis.md) · [third-party-integrations](04-build/third-party-integrations.md) · [secrets-config](04-build/secrets-config.md) · [developer-experience](04-build/developer-experience.md) |
| [`05-verification/`](05-verification/) | [definition-of-done](05-verification/definition-of-done.md) · [code-review-standard](05-verification/code-review-standard.md) · [ci-pipeline](05-verification/ci-pipeline.md) · [a11y-perf-gates](05-verification/a11y-perf-gates.md) · [load-testing](05-verification/load-testing.md) |
| [`06-delivery/`](06-delivery/) | [deployment-strategy](06-delivery/deployment-strategy.md) · [release-process](06-delivery/release-process.md) · [migration-discipline](06-delivery/migration-discipline.md) · [rollback](06-delivery/rollback.md) · [launch-readiness](06-delivery/launch-readiness.md) · [infrastructure-as-code](06-delivery/infrastructure-as-code.md) |
| [`07-operations/`](07-operations/) | [observability](07-operations/observability.md) · [product-analytics](07-operations/product-analytics.md) · [incident-runbook.template](07-operations/incident-runbook.template.md) · [oncall-escalation](07-operations/oncall-escalation.md) · [slo-error-budgets](07-operations/slo-error-budgets.md) · [error-budget-policy](07-operations/error-budget-policy.md) · [backup-dr](07-operations/backup-dr.md) · [audit-log-retention](07-operations/audit-log-retention.md) |
| [`08-maintenance/`](08-maintenance/) | [dependency-updates](08-maintenance/dependency-updates.md) · [tech-debt-policy](08-maintenance/tech-debt-policy.md) · [deprecation-process](08-maintenance/deprecation-process.md) |
| [`_spines/`](_spines/) | [security-privacy](_spines/security-privacy.md) · [version-control](_spines/version-control.md) · [performance](_spines/performance.md) · [reliability](_spines/reliability.md) · [accessibility](_spines/accessibility.md) · [cost](_spines/cost.md) · [compliance](_spines/compliance.md) · [documentation](_spines/documentation.md) — cross-cutting concerns, referencing where they bite in each layer |
| [`stacks/`](stacks/) | [README (preset contract)](stacks/README.md) · [`nextjs-default/`](stacks/nextjs-default/) (serverless + Drizzle) · [`nextjs-container/`](stacks/nextjs-container/) (warm-Node deviation: Prisma + container) |
| [`scripts/`](scripts/) | [new-project.sh](scripts/new-project.sh) (bootstrap) · [audit-completeness.sh](scripts/audit-completeness.sh) (footer audit) · [check-calibration.sh](scripts/check-calibration.sh) (knob-drift + manifest↔row coherence + tracked-files inventory vs the calibration register) · [check-flowback.sh](scripts/check-flowback.sh) (flow-back ledger integrity) · [check-presets.sh](scripts/check-presets.sh) (preset manifest coherence; RUN_INSTALL=1 resolves the dependency graph) · [suite-ci.sh](scripts/suite-ci.sh) (library QA: footers + calibration + flow-back + links + anchors + configs + bootstrap smoke + preset coherence) · [metrics.sh](scripts/metrics.sh) (informational suite-health report: structure, calibration coverage, flow-back throughput, currency-pass due) |

## For AI agents

- Working **on this library**: read the root [`CLAUDE.md`](CLAUDE.md) — footer contract, never-stub rule, rules-vs-choices placement, phased-build expectation.
- Working **on a project bootstrapped from this library**: the project's own `CLAUDE.md` is your index; [`00-governance/agent-operating-rules.md`](00-governance/agent-operating-rules.md) is binding.

## Maintaining the library

Lessons from projects come back as **small patches**, not rewrites — process in [`00-governance/standards-lifecycle.md`](00-governance/standards-lifecycle.md). After any change: run `./scripts/audit-completeness.sh` and update the completeness matrix. For a quick read on the suite's overall health (and whether the currency pass is due), run `./scripts/metrics.sh`. Every change is checked by [`scripts/suite-ci.sh`](scripts/suite-ci.sh) (footers, calibration register, flow-back ledger, internal links, config validity, bootstrap smoke test), which CI runs on every push and pull request.
