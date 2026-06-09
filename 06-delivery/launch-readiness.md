# Launch Readiness Review

Every other standard gates a *change*; this one gates a *launch*. The pieces of "are we ready for real users?" live in a dozen docs — SLOs, backups, runbooks, threat model, perf/a11y gates, rollback. This is the single **go/no-go review** that confirms they're all actually true before first production traffic (and before any launch-significant change after it), so readiness is a decision on the record, not an assumption.

## The review

Run the review against the injected `docs/launch-readiness.md` checklist; each item is **pass / fail / N-A-with-reason**, and a fail on a load-bearing item **blocks launch** or becomes an explicitly recorded, signed risk acceptance. The categories and where each is owned:

1. **Reliability.** SLOs declared from a baseline (`07-operations/slo-error-budgets.md`); error-budget policy set (`07-operations/error-budget-policy.md`); a backup has been taken **and a restore verified** (`07-operations/backup-dr.md` — an unrestored backup doesn't count); the rollback path is proven by a drill (`06-delivery/rollback.md`); the incident runbook exists and alerts page a real destination (`07-operations/incident-runbook.template.md`, `oncall-escalation.md`).
2. **Security & privacy.** The launch-critical features have a threat model with mitigations implemented (`03-design/threat-modeling.md`); no secrets in the repo and env is boot-validated (`04-build/secrets-config.md`); the dependency audit + supply-chain gates are green (`04-build/dependency-policy.md`, `supply-chain.md`); PII is classified and DSR/retention are satisfiable (`03-design/data-privacy.md`).
3. **Quality.** The full CI + nightly tier is green on the release commit (`05-verification/ci-pipeline.md`); performance budgets pass and, where applicable, a load test clears the latency SLO (`_spines/performance.md`, `05-verification/load-testing.md`); the accessibility gate is green (`_spines/accessibility.md`).
4. **Delivery.** Deploy and rollback are rehearsed (`06-delivery/deployment-strategy.md`); risky surfaces are behind flags/kill-switches (`06-delivery/release-process.md`); the release/changelog process works; branch + tag protection and required checks are on (`_spines/version-control.md`).
5. **Compliance (if in scope).** The controls and evidence for the launch are in place per `_spines/compliance.md`.
6. **The review is recorded and dated.** The completed checklist with its go/no-go decision and any signed risk acceptances is committed (`docs/launch-readiness.md`) — a launch is a deliberate, auditable decision, repeated before any later launch-significant change (new region, new data class, major rearchitecture).

## Standards basis

- **Google SRE — Production Readiness Review (PRR) & Launch Coordination Engineering** (*Site Reliability Engineering*, ch. "Reliable Product Launches" / "Evolving the PRR"): a structured pre-launch review that a service passes before it carries production traffic — the direct basis for this doc; the launch checklist as a Launch Coordination practice.
- **AWS Well-Architected — Operational Readiness Reviews (ORR)** (Operational Excellence pillar): a consolidated readiness checklist distilled from prior incidents, run before go-live; corroborates the category structure and the "recorded decision" rule.
- **The Twelve-Factor App** and **DORA** deployment/rollback practices ground the Delivery category (rehearsed deploy + instant rollback).
- This doc is a pure aggregator — it owns no new rule, only the gate; each category defers to its owning standard, so it can never drift from them.

## Enforcement
- Mechanism: none-possible
- Config: n/a — the categories are each gated in their own layer; this is the consolidating launch gate.
- Fallback if unenforceable: Before first production launch (or a launch-significant change — new region, new data class, major rearchitecture), the launch-readiness checklist passes: SLOs + error-budget set, a backup restore-verified, rollback drilled, runbook + alerting wired, threat model done, secrets/deps/supply-chain green, perf + a11y (+ load where applicable) gates green, branch/tag protection on — with any fail recorded as a signed risk acceptance.

## Bootstrap
- What new-project.sh injects for this standard: `docs/launch-readiness.md` — the fill-in go/no-go checklist, ready to complete before launch.
