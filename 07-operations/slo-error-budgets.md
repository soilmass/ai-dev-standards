# SLOs & Error Budgets

Reliability targets you set on purpose, and what happens when you spend them. Solo projects skip this and end up with an implicit SLO of "whatever last week was" — set a thin, real version instead.

## Setting SLOs — the thin real version

1. Pick **2–3 SLIs** that track user-felt health, no more:
   - **Availability:** share of requests that succeed (non-5xx).
   - **Latency:** share of requests faster than a threshold (e.g. p95 < 500 ms on API routes).
   - Optionally one **journey SLI** for the revenue-critical flow (checkout completes, login succeeds).
2. Set each target from **measured reality minus ambition**: run a month, look at the data (`observability.md` metrics), set the SLO slightly above current performance — not at 99.99% because it sounds professional. A solo-operated app with no on-call rotation has no business promising more than ~99.5% anywhere.
3. Write them down in the project — the bootstrap drops a `docs/slos.md` starter (from `07-operations/slos.template.md`: SLI/target/window table, burn-alert column, RPO/RTO, verified-restore log). An SLO that lives in your head is a mood, not an objective.

## Error budgets

4. The budget is the complement of the target over a rolling window: 99.5% availability over 30 days ≈ 3.6 hours of failure to spend.
5. **Burn alerts, not threshold alerts:** alert on **error-budget burn rate** (consumption speed relative to the SLO), which catches both hard outages and slow bleeds (`observability.md` rule 11). The SRE-canonical shape is **multi-window, multi-burn-rate** — pair a fast/short window with a slower/long window so the alert fires only when *both* agree, killing flapping while keeping fast detection. The recommended page tier is ~14.4× burn (≈2% of a 30-day budget in 1h, confirmed over a 5-min short window); a slower ~6× tier (≈5% in 6h) and a ticket-level ~3× tier (≈10% in 24h) catch sustained drift. A solo project can start with the single page tier and add the slower tiers as traffic justifies the tuning.

## When the budget burns

6. **Budget healthy** → ship features at full speed. The budget exists to be spent; 100% reliability is over-investment.
7. **Budget exhausted (or burning hot)** → the next unit of work is reliability work, not features: fix the regression, add the missing guard, finish the runbook that didn't exist. This trade is the entire point of the mechanism — it converts "should I harden or build?" from a feeling into a rule.
8. Repeated burns from the same cause escalate to an ADR-level decision (different host box, different design) rather than a third patch (`00-governance/standards-lifecycle.md` feedback loop).

## Review cadence

9. Glance at budget status when releasing (`06-delivery/release-process.md` step 4); review SLO targets quarterly — targets that are never threatened are too loose, targets always in breach are dishonest.

## Standards basis
- **Google SRE — SLI/SLO/error-budget model** (*SRE* book "Service Level Objectives", https://sre.google/sre-book/service-level-objectives/; *SRE Workbook* "Implementing SLOs"): an SLI is a measured ratio of good to total events, an SLO is a target on it over a window, and the error budget is the complement (1 − target). Grounds rules 1, 4, and the spend-the-budget framing in rules 6–7 — the budget exists to be spent, and 100% is the wrong target.
- **SRE Workbook — Alerting on SLOs** (multi-window, multi-burn-rate; https://sre.google/workbook/alerting-on-slos/): burn-rate = error-rate ÷ (1 − SLO); the recommended tiers (14.4× / 6× / 3× across paired short+long windows) trade detection speed against alert volume. Rule 5 adopts this directly; burn = how fast the budget is consumed relative to the SLO.
- **Error-budget policy as the build-vs-harden decision rule**: SRE makes budget status gate feature velocity — heal-vs-ship is decided by data, not feeling. Grounds rules 6–8 and the release-time glance in rule 9.
- **Choose SLIs/targets from measured reality**: SRE warns against aspirational targets ("99.99% because it sounds professional"); rule 2's "measured reality minus ambition" and the quarterly review in rule 9 enforce that targets stay both honest and meaningful.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this change can move a user-facing SLI (latency, availability, error rate), state the expected impact on the SLO in the PR description.

## Bootstrap
- What new-project.sh injects for this standard: `docs/slos.md` (from `slos.template.md`) — the targets are filled in once real traffic exists; this doc is the recipe.
