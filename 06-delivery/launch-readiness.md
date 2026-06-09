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

## What makes a fail an acceptable risk

A failed checklist item is not automatically a blocker — but it is only acceptable as a **signed risk acceptance** if every one of these is true and recorded next to the item; absent any of them, the item blocks launch.

7. **The blast radius is bounded and named.** A fail is acceptable only when the worst realistic outcome is understood and contained — which users, which data, which revenue path, for how long. An item whose failure mode is unbounded (data loss, an irreversible action, exposure of a sensitive data class) is never a signed risk; it is a blocker. The acceptance states the bound, not just "low risk".
8. **There is a real mitigation, not a hope.** The acceptance names the compensating control that shrinks the unmitigated risk — a flag that disables the surface, a manual fallback, tightened monitoring on the exact failure signal, a rate cap. "We'll watch it" is a mitigation only if the watch is a wired alert with an owner, not an intention.
9. **It is time-boxed with a remediation plan.** A signed risk carries a concrete remediation — the work that retires it — and a hard expiry date by which that work lands. An acceptance with no expiry is a permanent waiver disguised as a launch decision; it is not allowed. If remediation slips the date, the risk is re-reviewed, not silently extended.
10. **It has a named accountable owner and an authorized signer.** One named person owns the remediation; one authorized person (with the standing to accept the consequence) signs the acceptance. An unsigned or owner-less "known issue" is an open blocker, not an accepted risk.
11. **It has a revisit date independent of remediation.** Even before the remediation deadline, each open signed risk is re-examined on a stated cadence (so an accepted-at-launch risk doesn't drift unwatched if conditions change). The revisit date and the expiry date are both written down; the acceptance is reviewed on the earlier of the two.

## Launch-significant change triggers

The full review is re-run — not a casual diff review — before any change that crosses one of these lines, because each invalidates assumptions the original go/no-go rested on.

12. **A new region or jurisdiction.** Serving a new geography changes the latency baseline (SLOs were set against the old one), the failure-domain map, and the legal regime governing the data (residency, transfer, and breach-notification obligations shift). Re-run reliability, security/privacy, and compliance categories before traffic.
13. **A new data class.** Introducing a class the original threat model never covered — first payment data, first health/biometric/sensitive PII, first data subject to a stricter regime — reopens classification, retention, DSR, and encryption decisions. The feature's threat model is redone before the column ships, and the security/privacy category is re-reviewed.
14. **A major rearchitecture.** Replacing the datastore, the auth model, the deployment topology, or splitting/merging services breaks the rollback drill, the backup/restore proof, and the runbook's accuracy. Treat it as a fresh launch of the changed surface: re-drill rollback, re-verify a restore, and re-validate the runbook against the new shape.
15. **A new payment processor or money-moving integration.** A new processor (or any new third party that moves money or holds payment credentials) changes the threat model, the compliance scope, and the kill-switch surface. Re-run security/privacy and compliance, and confirm the integration sits behind a kill switch before it takes live transactions.
16. **Scaling past a known limit.** Crossing a documented capacity ceiling — a connection-pool cap, a rate limit, a quota, a partition/shard boundary, a tier threshold — invalidates the load test the original review accepted. Re-run the quality category's load test against the new ceiling before the traffic that would cross it arrives.

## Launch-day mechanics

The go decision authorizes a controlled exposure, not an instant cut-over. Two mechanics are decided and wired *before* launch day, not improvised under live traffic.

17. **Traffic ramps; it does not flip.** First production traffic is admitted in stages against a healthy baseline — a small slice, hold and observe the launch-critical signals, widen only while they stay green. Each stage has explicit promote/hold criteria tied to the SLOs and error budget (`07-operations/slo-error-budgets.md`, `06-delivery/deployment-strategy.md`); a stage that fails its criteria holds rather than advancing. The ramp plan and its gates are part of the recorded review.
18. **The kill switch has a pre-agreed trigger and a named puller.** Before launch, the team writes down the exact condition that aborts the ramp and reverses exposure — a breached error-budget burn rate, a spike on a named failure signal, a data-integrity alarm — and who is authorized to pull it without convening a meeting. The reversal path is the already-drilled rollback / flag-disable (`06-delivery/rollback.md`, `06-delivery/release-process.md`); launch day adds only the *threshold* that fires it. An undefined trigger means the switch effectively doesn't exist.

## Standards basis

- **Google SRE — Production Readiness Review (PRR) & Launch Coordination Engineering** (*Site Reliability Engineering*, ch. "Reliable Product Launches" / "Evolving the PRR"): a structured pre-launch review that a service passes before it carries production traffic — the direct basis for this doc; the launch checklist as a Launch Coordination practice. The PRR's coverage of **system design, monitoring/alerting readiness, and incident-response readiness** as distinct review dimensions is the basis for the reliability category's split across SLOs, alerting-paging, and runbook/escalation; the PRR's staged "graduate the service onto production traffic" model grounds the traffic-ramp mechanic (rule 17).
- **AWS Well-Architected — Operational Readiness Reviews (ORR)** (Operational Excellence pillar, *OPS questions on readiness*): a consolidated readiness checklist distilled from prior incidents and run before go-live, with explicit **governance** — accountable ownership of each item, recorded decisions, and reuse of the checklist as a repeatable gate. This governance framing is the basis for the recorded-and-dated rule (rule 6) and the named-owner/authorized-signer condition on a risk acceptance (rule 10); the "distilled from prior incidents" property is why launch-significant changes (rules 12–16) re-open the checklist rather than trusting the prior pass.
- **The Twelve-Factor App** and **DORA** deployment/rollback practices ground the Delivery category and the launch-day mechanics: DORA's findings that elite performers rely on **small batch sizes, progressive delivery, and fast reversible rollout** underwrite the staged traffic ramp (rule 17) and the pre-wired kill switch / instant rollback (rule 18) over a single cut-over.
- **NIST SP 800-37 (Risk Management Framework) — Authorize step** and the **plan-of-action-and-milestones (POA&M)** construct: an authorizing official accepts residual risk on the record, and unresolved weaknesses are tracked with a remediation plan and a milestone date rather than left open-ended. This is the established shape behind the signed-risk-acceptance criteria (rules 7–11): bounded residual risk, a recorded mitigation, an owner, a time-boxed remediation, and a revisit cadence.
- This doc is a pure aggregator — it owns no new gate-category rule, only the launch gate, the risk-acceptance criteria that govern its fails, and the launch-day mechanics; each readiness category still defers to its owning standard, so it can never drift from them.

## Enforcement
- Mechanism: none-possible
- Config: n/a — the categories are each gated in their own layer; this is the consolidating launch gate.
- Fallback if unenforceable: Before first production launch (or a launch-significant change — new region, new data class, major rearchitecture), the launch-readiness checklist passes: SLOs + error-budget set, a backup restore-verified, rollback drilled, runbook + alerting wired, threat model done, secrets/deps/supply-chain green, perf + a11y (+ load where applicable) gates green, branch/tag protection on — with any fail recorded as a signed risk acceptance.

## Bootstrap
- What new-project.sh injects for this standard: `docs/launch-readiness.md` — the fill-in go/no-go checklist, ready to complete before launch.
