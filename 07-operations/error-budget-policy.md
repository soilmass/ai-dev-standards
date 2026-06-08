# Error Budget Policy

The *policy* is the documented, pre-agreed answer to "what happens when the budget runs out" — written before it runs out, while you can still reason calmly. `07-operations/slo-error-budgets.md` defines the SLIs, SLOs, and the budget (the *measurement*); this doc makes the budget *consequential*. Without it the budget is just another dashboard number, not a decision rule. Solo operators need this *more*, not less: the policy is what stops you from negotiating with yourself in the middle of a fire.

## Why a written policy

1. A budget with no consequence is a metric, not a control. The point of the policy is to convert "should I harden or keep building?" from a mood into a pre-committed rule — decided once, in advance, by someone who isn't currently shipping a feature.
2. **Write it before you need it.** A policy authored mid-incident is a rationalization. Author it when the budget is healthy; it then binds the version of you that wants to ship anyway.

## Ownership

3. The canonical policy is co-signed by three parties — product, development, SRE — and that tri-party agreement is itself the validation that the SLO is realistic (if you won't agree to freeze for it, you don't believe the target). For a solo operator the three roles collapse into **one person making a self-commitment**, recorded in `docs/slos.md` and dated. The signature is real even when there's only one of you; it's the difference between a rule and an intention.
4. State explicitly **who declares the freeze** and **who does the reliability work**. Solo: both are you, but name the trigger so the declaration is mechanical (budget status, not gut feel) — see rule 6.

## Budget healthy → ship

5. While the budget is within bounds, **releases proceed at full speed** under the normal release flow (`06-delivery/release-process.md`). The budget exists to be spent; an unspent budget is over-investment in reliability you could have spent on product. Do not self-impose extra caution because the number "looks low but not empty" — the policy, not anxiety, governs.

## Budget exhausted → the freeze trade

6. When the budget is **exhausted or burning hot** (the page-tier multi-window burn-rate alert from `07-operations/slo-error-budgets.md` rule 5 is the mechanical trigger), the next unit of work is **reliability work, not features**: a **feature freeze** holds all non-essential change until the service is back within SLO.
7. Frame the freeze correctly: halting change is undesirable, and the policy's job is to give you **permission to focus exclusively on reliability when the data says reliability now matters more than the next feature**. It is a control mechanism, not a punishment. The freeze ends automatically when the budget recovers — it is self-lifting, not a vibe to be argued away.
8. The freeze is scoped to **feature/risk-bearing change**, not to everything. Reliability fixes, the regression that caused the burn, the missing guard, and the runbook that didn't exist are exactly what you ship *during* the freeze.

## Exceptions and overrides

9. **P0 / security carve-out:** changes that fix a P0 incident or a security vulnerability are always permitted during a freeze — withholding a security fix to protect a reliability budget is incoherent.
10. **Silver bullets:** allow a *very small, pre-counted* number of business-critical emergency launches that may proceed despite the freeze. Keep the count tiny and spend it visibly. Do not invent new exception categories beyond this and rule 9 — every soft exception teaches you that breaching reliability is acceptable, which nullifies the incentive the policy exists to create.
11. **Budget-not-at-fault:** burn caused by factors outside the service's control does **not** trigger the freeze — upstream/infrastructure-wide outages, third-party dependency failures, out-of-scope traffic, or mis-categorized errors with no real user impact. Conversely, internal code bugs and procedural errors **do** trigger it. Record which determination you made and why.
12. **Disputes escalate, they don't dissolve.** In a team the canonical escalation is to a higher authority (e.g. the CTO) for a final call. Solo, the escalation path is to **stop and write it down**: if you find yourself wanting to override the policy, that disagreement is the signal to return to the policy-approval step (rule 3) and renegotiate the *policy* deliberately — not to quietly ignore it this once. Repeated overrides mean the SLO is wrong; fix the target, not the rule.
13. Repeated freezes from the **same root cause** escalate past patching to an ADR-level decision (different design, different host) rather than a third hotfix — see `07-operations/slo-error-budgets.md` rule 8 and `00-governance/standards-lifecycle.md`.

## Review cadence

14. **Glance at budget status at every release** (`06-delivery/release-process.md` step 4) — that glance is what actually invokes rules 5–6.
15. **Review the policy itself on a fixed cadence:** monthly while the SLO is new and unproven, relaxing to **quarterly** once targets are stable. A policy never invoked may be too loose (targets never threatened) or dead (you've been silently overriding it) — the review is where you catch both. Re-sign and re-date `docs/slos.md` at each review so the self-commitment stays current rather than fossilized.

## Standards basis
- **Google SRE Workbook — "Error Budget Policy" (Example) and Appendix B** (https://sre.google/workbook/error-budget-policy/): the documented, pre-approved policy that "covers the specific actions that must be taken when a service has consumed its entire error budget … and specifies who will take them." Grounds the healthy-state release rule (rule 5), the exhausted-state P0/security-only freeze (rules 6, 9), the explicit "halting change is undesirable … permission to focus exclusively on reliability" framing (rule 7), the budget-not-at-fault carve-outs (rule 11), and escalation of disputes (rule 12). Authored/reviewed/approved-and-dated with an annual revisit in the canonical example — grounds the ownership signature (rule 3) and review cadence (rule 15).
- **SRE Workbook — "Implementing SLOs"** (https://sre.google/workbook/implementing-slos/): "In order to use this error budget, you need a policy outlining what to do when your service runs out of budget"; without enforcement "SLO compliance will simply be another KPI … rather than a decision-making tool" (rules 1–2). The policy is approved by "the product manager, the development team, and the SREs," and disagreement means returning to the approval stage (rules 3, 12). Typical exhaustion actions — top-priority reliability bugs, exclusive reliability focus, production freeze — ground rules 6–8. Review "perhaps every month … reduce to quarterly or less" grounds rule 15.
- **SRE silver-bullet exceptions** (Workbook, error-budget/maintenance-window guidance): a "very small number of exceptions for truly business-critical emergency launches," with a caution that broader exceptions create a culture where failing reliability is accepted — grounds rule 10.
- **SRE Workbook — "Alerting on SLOs" (multi-window, multi-burn-rate)** (https://sre.google/workbook/alerting-on-slos/): the page-tier burn-rate alert is the mechanical trigger for declaring a freeze (rule 6); the alerting model itself is owned by `07-operations/slo-error-budgets.md` rule 5 and not re-derived here.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If the error budget is exhausted or burning at the page tier, confirm this change is reliability, P0, or security work — or a recorded silver-bullet exception — and not a feature shipped during a freeze.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only. The signed/dated policy lives in `docs/slos.md` (injected from `07-operations/slos.template.md` by the SLO standard); this doc is the policy it commits you to.
