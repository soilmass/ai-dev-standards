# Reliability & Resilience Spine

Reliability is not a layer — it's whether the system keeps its promise when something goes wrong, and every layer either contains a failure or propagates it. This spine doesn't duplicate the layer rules; it shows **where reliability bites in each layer**, owns the cross-cutting resilience patterns, and ties design-time failure thinking to ops-time recovery.

## Where it bites, layer by layer

| Layer | Reliability obligation | Lives in |
|---|---|---|
| 02 Product | Acceptance criteria name the **unhappy paths** (empty, denied, timeout, partial failure), not just the happy one | `02-product/acceptance-criteria.md` |
| 03 Design | Error envelopes that leak nothing and are actionable; the feature's **failure modes + degradation strategy** decided up front | `03-design/api-contract-design.md`, `03-design/threat-modeling.md` |
| 04 Build | Every outbound call has a **timeout + bounded retry + circuit breaker + fallback**; inputs validated at the boundary | `04-build/third-party-integrations.md`, `03-design/rate-limiting-abuse.md` |
| 05 Verification | Tests cover failure paths, not just success — the degraded state is asserted | `04-build/testing-strategy.md` (failure-path coverage), `05-verification/code-review-standard.md` |
| 06 Delivery | Risky changes ship behind a flag/kill-switch; every change has a **stated rollback path**; migrations are reversible-safe | `06-delivery/rollback.md`, `06-delivery/migration-discipline.md` |
| 07 Operations | SLOs + burn-rate alerts; incident runbook + postmortem; restore-verified backups as the corruption/ransomware floor | `07-operations/slo-error-budgets.md`, `07-operations/error-budget-policy.md`, `07-operations/incident-runbook.template.md`, `07-operations/backup-dr.md` |
| 08 Maintenance | Reliability debt (a missing timeout, an untested failure path) is logged with a paydown trigger | `08-maintenance/tech-debt-policy.md` |

## Cross-cutting rules owned here

1. **Decide each feature's failure modes before building it.** For every external call, shared resource, and entry point (the same surfaces the threat model enumerates, `03-design/threat-modeling.md`) name what happens when it is slow, down, or returns garbage — and pick the response: **fail hard** (no payment authorization → no order), **degrade** (analytics down → drop the event, never the page), or **serve stale** (cache the last good value). "It won't fail" is not a failure mode.
2. **Every outbound dependency is wrapped the same way: timeout + bounded retry (backoff, jitter, idempotent only) + circuit breaker + fallback.** This is the single most important reliability rule and it is stated in full in `04-build/third-party-integrations.md` rules 4–7; this spine elevates it to a universal contract — a dependency without a timeout is the textbook cascading failure, regardless of which feature added it.
3. **Degrade visibly, and observe the degraded state separately from errors.** A system serving stale-but-correct data is healthy-degraded, not broken; emit a metric that distinguishes "serving fallback / circuit open" from "erroring" (`07-operations/observability.md`), so an alert fires on real user pain (the SLI), not on a breaker doing its job. A silent degradation that no one can see is indistinguishable from a silent outage.
4. **Reversibility is a design property, not a hope.** Every change states how it is undone — feature-flag off, redeploy the prior build, or `git revert` (`06-delivery/rollback.md`) — and schema changes use the expand→migrate→contract path so the old code still runs against the new schema (`06-delivery/migration-discipline.md`). A change you cannot roll back is a change you cannot ship safely.
5. **A backup that has never been restored is a wish.** Recoverability is proven, not assumed: the restore-verified backup ladder and the periodic + pre-destructive-migration restore drill (`07-operations/backup-dr.md`) are the floor under data loss. RPO/RTO are derived from the actual cadence and a *measured* restore, not aspirations.
6. **An untested failure path is an unreliable one.** Reliability claims are backed by tests: the failure paths named in rule 1 each have a test that exercises the degraded/erroring branch (`04-build/testing-strategy.md`), and a flaky test is a reliability defect fixed at P1, never retried-until-green.

## Standards basis

- **Google SRE — SLOs, error budgets, and the Four Golden Signals** (sre.google/sre-book) — reliability is an explicit, measured target with a budget, not "as much as possible"; grounds the ops row and rule 3 (alert on user-facing SLIs). Owned in `07-operations/slo-error-budgets.md`.
- **Michael Nygard, *Release It!* — Stability patterns** (Timeout, Circuit Breaker, Bulkhead, Fail Fast, Steady State, and the Cascading-Failure / Integration-Point antipatterns): the canonical basis for rules 1–2; an integration point without a timeout + breaker is the named failure mode.
- **Exponential backoff with jitter** (AWS Architecture Blog) and **idempotency keys**: rule 2's safe-retry discipline — bounded, jittered, idempotent, so a blip isn't amplified into a self-inflicted storm.
- **Graceful degradation / fault tolerance** (the long-standing resilience principle) and **expand–contract / parallel change** (Fowler) — the basis for rules 1, 3 (degrade visibly) and 4 (reversible migrations).
- **3-2-1 backup rule + restore verification** (US-CERT/CISA backup guidance) — rule 5; a backup is only real once a restore has succeeded. Owned in `07-operations/backup-dr.md`.
- Builds on `04-build/third-party-integrations.md` (the per-call resilience contract — owned there), `06-delivery/rollback.md` + `06-delivery/migration-discipline.md` (reversibility), `07-operations/*` (SLOs/incidents/backups), and `02-product/acceptance-criteria.md` (unhappy paths). This spine is the map that makes them one reliability story.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/nightly.yml (restore-test job) + stacks/nextjs-default/ci/pr.yml (test job — failure-path coverage) — the mechanical subset; each layer row above names its own gate.
- Fallback if unenforceable: n/a — backups and tests are CI-gated, and the design-judgment pieces (failure modes, degradation, timeouts, rollback path) ride the existing third-party-integration, rollback, SLO-impact, and runbook fallback lines already in `05-verification/code-review-standard.md` §E.

## Bootstrap
- What new-project.sh injects for this standard: nothing additional — the nightly restore-test job, the test scaffolding, the `docs/slos.md` + incident-runbook templates, and the rollback/migration discipline it already injects are this spine's enforcement surface.
