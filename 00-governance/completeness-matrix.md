# Completeness Matrix

The live grid: every layer cell of the suite against the four-test quality bar (see `README.md`). Each cell links the satisfying file or names the gap explicitly — a cell is never silently blank. The executable subset of this matrix is `scripts/audit-completeness.sh` (footer presence + fallback aggregation); **re-run it after adding or changing any standard, and update this grid in the same commit.**

Column meanings — **Articulated**: rule written concretely. **Templated**: fill-in artifact exists where one is the deliverable. **Enforced**: mechanical gate, or declared `none-possible` with its fallback aggregated into the self-review checklist. **Bootstrappable**: `new-project.sh` injects it, or the doc states "reference only".

| Layer cell | Articulated | Templated | Enforced | Bootstrappable |
|---|---|---|---|---|
| **00 Governance** | — | — | — | — |
| Standards lifecycle | [standards-lifecycle.md](standards-lifecycle.md) | n/a — process doc | gap (accepted): process is human-arbitered by design | reference only |
| Agent operating rules | [agent-operating-rules.md](agent-operating-rules.md) | n/a — rules doc | partially: never-touch items backed by hooks/CI ([pre-commit](../stacks/nextjs-default/hooks/pre-commit), [pr.yml](../stacks/nextjs-default/ci/pr.yml)); rest rides [code-review-standard.md](../05-verification/code-review-standard.md) | linked from every bootstrapped `CLAUDE.md` |
| Pinned decisions | [pinned-decisions.md](pinned-decisions.md) | n/a — reference | gap (accepted): currency relies on the lifecycle's twice-yearly pass | consumed via preset ADRs |
| Completeness matrix | this file | n/a | [audit-completeness.sh](../scripts/audit-completeness.sh), run with the wider library QA by [suite-ci.sh](../scripts/suite-ci.sh) on every push/PR ([suite-ci.yml](../.github/workflows/suite-ci.yml)) | reference only |
| Calibration register | [calibration.md](calibration.md) — every tunable knob: value, rationale, recalibration trigger, + an Observations log of triggers fired against real data | n/a — the register is the artifact | [check-calibration.sh](../scripts/check-calibration.sh) verifies register ↔ tree values AND manifest-id ↔ row coherence, every push/PR via suite CI | n/a — lives in the library |
| Feedback loop | [flow-back-log.md](flow-back-log.md) + [standards-lifecycle.md](standards-lifecycle.md) §6 — the cross-project ledger of findings → dispositions | debt-log template's "Library flow-back" section is the project-side intake shape | [check-flowback.sh](../scripts/check-flowback.sh) (ids/dispositions/patched-tag-exists) via suite CI; harvest into the ledger is a manual currency-pass step | n/a — lives in the library; projects emit via the injected debt-log template |
| **01 Context** | — | — | — | — |
| Project agent index | [CLAUDE.template.md](../01-context/CLAUDE.template.md) | same file | n/a — template | [new-project.sh](../scripts/new-project.sh) assembles `CLAUDE.md` |
| ADRs | [adr.template.md](../01-context/adr.template.md) | same file | n/a — template | injected to `docs/` |
| Glossary | [glossary.template.md](../01-context/glossary.template.md) | same file | n/a — template | injected to `docs/` |
| Architecture map | [architecture-map.template.md](../01-context/architecture-map.template.md) | same file | freshness via docs-check ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | injected to `docs/` |
| **02 Product** | — | — | — | — |
| Specs | [spec.template.md](../02-product/spec.template.md) | same file | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | injected to `docs/` |
| Task decomposition | [task-decomposition.md](../02-product/task-decomposition.md) | n/a | CI pr-size gate ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | via PR workflow |
| Acceptance criteria | [acceptance-criteria.md](../02-product/acceptance-criteria.md) | spec template carries the section | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| Definition of Ready/Done (item gate) | [definition-of-ready-done.md](../02-product/definition-of-ready-done.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| **03 Design** | — | — | — | — |
| Architecture standards | [architecture-standards.md](../03-design/architecture-standards.md) | architecture-map template | deep-import lint only ([biome.json](../stacks/nextjs-default/lint-config/biome.json)) — partial: full layering/dependency-direction is review-carried via the architecture map | via lint config |
| Data modeling | [data-modeling.md](../03-design/data-modeling.md) | n/a | CI migrations guard ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) — pathspec pinned by the injected [drizzle.config.example.ts](../stacks/nextjs-default/project-config/drizzle.config.example.ts) | via PR workflow + injected ORM config |
| API contracts | [api-contract-design.md](../03-design/api-contract-design.md) | n/a — schemas are the artifact | typecheck + boundary tests ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | reference only |
| UI design system | [ui-design-system.md](../03-design/ui-design-system.md) | n/a | a11y lint + Lighthouse gates ([biome.json](../stacks/nextjs-default/lint-config/biome.json), [lighthouserc.json](../stacks/nextjs-default/ci/lighthouserc.json)) | via lint config + workflows |
| Threat modeling (artifact) | [threat-model.template.md](../03-design/threat-model.template.md) | same file | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | injected to `docs/` |
| Threat modeling (methodology) | [threat-modeling.md](../03-design/threat-modeling.md) | the template is its output | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| API evolution | [api-evolution.md](../03-design/api-evolution.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| UI accessibility patterns | [ui-accessibility-patterns.md](../03-design/ui-accessibility-patterns.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md); markup baseline lint-backed | reference only |
| Data privacy | [data-privacy.md](../03-design/data-privacy.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| **04 Build** | — | — | — | — |
| Coding standards | [coding-standards.md](../04-build/coding-standards.md) | n/a | lint ([biome.json](../stacks/nextjs-default/lint-config/biome.json)) | via lint config |
| Git standards | [git-standards.md](../04-build/git-standards.md) | PR template ([PULL_REQUEST_TEMPLATE.md](../stacks/nextjs-default/ci/PULL_REQUEST_TEMPLATE.md)) | hooks ([pre-commit](../stacks/nextjs-default/hooks/pre-commit), [commitlint.config.mjs](../stacks/nextjs-default/hooks/commitlint.config.mjs)) | via `.husky/` + configs |
| Testing strategy | [testing-strategy.md](../04-build/testing-strategy.md) | test-runner configs with thresholds ([vitest.config.example.ts](../stacks/nextjs-default/project-config/vitest.config.example.ts), [playwright.config.example.ts](../stacks/nextjs-default/project-config/playwright.config.example.ts)) | coverage gate (thresholds in injected config) + nightly tiers ([pr.yml](../stacks/nextjs-default/ci/pr.yml), [nightly.yml](../stacks/nextjs-default/ci/nightly.yml)) | via workflows + injected configs |
| Dependency policy | [dependency-policy.md](../04-build/dependency-policy.md) | n/a | CI deps job: audit + license allowlist ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | via PR workflow |
| Secrets & config | [secrets-config.md](../04-build/secrets-config.md) | env schema ([env.schema.example](../stacks/nextjs-default/env.schema.example)) | secret scan + boot validation ([pre-commit](../stacks/nextjs-default/hooks/pre-commit), [pr.yml](../stacks/nextjs-default/ci/pr.yml)) | `env.schema.ts` + hooks + workflow |
| Supply-chain security | [supply-chain.md](../04-build/supply-chain.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md); dep audit/license gate partial ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | reference only |
| **05 Verification** | — | — | — | — |
| Definition of done | [definition-of-done.md](../05-verification/definition-of-done.md) | PR template ([PULL_REQUEST_TEMPLATE.md](../stacks/nextjs-default/ci/PULL_REQUEST_TEMPLATE.md)) | required CI checks ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | PR template + workflows |
| Self-review (AI) | [code-review-standard.md](../05-verification/code-review-standard.md) | the checklist itself | none-possible → self-aggregating | reference only |
| CI pipeline | [ci-pipeline.md](../05-verification/ci-pipeline.md) | n/a — workflows are the artifact | the pipeline itself ([pr.yml](../stacks/nextjs-default/ci/pr.yml), [nightly.yml](../stacks/nextjs-default/ci/nightly.yml)) | via workflows |
| A11y & perf gates | [a11y-perf-gates.md](../05-verification/a11y-perf-gates.md) | budgets file ([lighthouserc.json](../stacks/nextjs-default/ci/lighthouserc.json)) | CI gates ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | budgets + workflow |
| **06 Delivery** | — | — | — | — |
| Deployment strategy | [deployment-strategy.md](../06-delivery/deployment-strategy.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| Release process | [release-process.md](../06-delivery/release-process.md) | n/a | commit-msg hook substrate ([commitlint.config.mjs](../stacks/nextjs-default/hooks/commitlint.config.mjs)) + tag-triggered changelog generation ([release.yml](../stacks/nextjs-default/ci/release.yml)) | via hooks + release workflow |
| Migration discipline | [migration-discipline.md](../06-delivery/migration-discipline.md) | n/a | CI migrations guard ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | via PR workflow |
| Rollback | [rollback.md](../06-delivery/rollback.md) | PR template rollback section | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | PR template |
| **07 Operations** | — | — | — | — |
| Observability | [observability.md](../07-operations/observability.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md); console ban lint-backed in production code (tests/scripts exempt by config) | reference only |
| Incident runbooks | [incident-runbook.template.md](../07-operations/incident-runbook.template.md) | same file | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | injected to `docs/` |
| SLOs & error budgets | [slo-error-budgets.md](../07-operations/slo-error-budgets.md) | [slos.template.md](../07-operations/slos.template.md) | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | injected as `docs/slos.md` |
| Backup & DR | [backup-dr.md](../07-operations/backup-dr.md) | n/a | nightly restore-test job ([nightly.yml](../stacks/nextjs-default/ci/nightly.yml)) | via nightly workflow |
| On-call & escalation | [oncall-escalation.md](../07-operations/oncall-escalation.md) | incident-runbook template is the per-scenario output | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| Error-budget policy | [error-budget-policy.md](../07-operations/error-budget-policy.md) | `docs/slos.md` carries the SLOs it governs | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| **08 Maintenance** | — | — | — | — |
| Dependency updates | [dependency-updates.md](../08-maintenance/dependency-updates.md) | n/a | update bot + deps gate ([dependabot.yml](../stacks/nextjs-default/dependabot.yml), [pr.yml](../stacks/nextjs-default/ci/pr.yml)) | `.github/dependabot.yml` |
| Tech debt | [tech-debt-policy.md](../08-maintenance/tech-debt-policy.md) | [debt-log.template.md](../08-maintenance/debt-log.template.md) | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | injected as `docs/debt-log.md` |
| Deprecation | [deprecation-process.md](../08-maintenance/deprecation-process.md) | n/a | none-possible → fallback in [checklist §E](../05-verification/code-review-standard.md) | reference only |
| **Spines** | — | — | — | — |
| Security & privacy | [security-privacy.md](../_spines/security-privacy.md) | threat-model template | mechanical subset gated per the spine's table (scans, audits, migration guard); PII/privacy policy rows are review-carried via the threat-model fallback | via injected hooks/workflows/schema |
| Documentation | [documentation.md](../_spines/documentation.md) | the `docs/` template set | CI docs-check ([pr.yml](../stacks/nextjs-default/ci/pr.yml)) | template set + workflow |
| **Stacks & scripts** | — | — | — | — |
| Preset contract | [stacks/README.md](../stacks/README.md) | [nextjs-default/](../stacks/nextjs-default/) is the worked example | [audit-completeness.sh](../scripts/audit-completeness.sh) keeps footer pointers honest | [new-project.sh](../scripts/new-project.sh) |
| Stack decisions | [stack-decisions.md](../stacks/nextjs-default/stack-decisions.md) | ADR template | gap (accepted): ADR currency is a lifecycle review item (checklist now in [pinned-decisions.md](pinned-decisions.md) § Currency pass) | n/a — lives in the library |
| Test scaffolding | [testing-strategy.md](../04-build/testing-strategy.md) | example setup/MSW/unit/e2e/visual files ([project-config/tests/](../stacks/nextjs-default/project-config/tests/)) | suite-ci bootstrap smoke asserts injection ([suite-ci.sh](../scripts/suite-ci.sh)) | injected to `tests/` |
| Library QA (this repo) | [suite-ci.sh](../scripts/suite-ci.sh) | n/a — the script is the artifact | [suite-ci.yml](../.github/workflows/suite-ci.yml) on every push/PR | n/a — lives in the library |
| Suite health metrics | [metrics.sh](../scripts/metrics.sh) — computed structure/calibration/flow-back/currency-pass report | n/a — computed, never stored (no drift) | informational, not a gate (by design — health informs, doesn't block) | n/a — lives in the library |

## Known gaps (explicit, not blank)

1. **Lifecycle & pinned-decisions currency** have no mechanical gate — they depend on the twice-yearly currency pass (`standards-lifecycle.md` §6.3). Accepted: a cron can't read the ecosystem.
2. **Branch protection** (required checks, no force-push) is a host-side setting `new-project.sh` cannot set; the exact checklist (incl. required-check names) is in `ci-pipeline.md` § "Branch protection — the one manual step".
3. **SLO/RUM tooling** is per-project (needs real traffic and a chosen vendor); the standards define shape and triggers only.

When adding a standard: write the doc with its footer → wire/point enforcement → add its row here → run `scripts/audit-completeness.sh`.
