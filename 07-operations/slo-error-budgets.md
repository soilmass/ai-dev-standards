# SLOs & Error Budgets

Reliability targets you set on purpose, and what happens when you spend them. Solo projects skip this and end up with an implicit SLO of "whatever last week was" — set a thin, real version instead.

## Setting SLOs — the thin real version

1. Pick **2–3 SLIs** that track user-felt health, no more:
   - **Availability:** share of requests that succeed (non-5xx).
   - **Latency:** share of requests faster than a threshold (e.g. p95 < 500 ms on API routes).
   - Optionally one **journey SLI** for the revenue-critical flow (checkout completes, login succeeds).
2. Set each target from **measured reality minus ambition**: run a month, look at the data (`observability.md` metrics), set the SLO slightly above current performance — not at 99.99% because it sounds professional. A solo-operated app with no on-call rotation has no business promising more than ~99.5% anywhere.
3. Write them down in the project (a short `docs/slos.md` listing SLI, target, window) — an SLO that lives in your head is a mood, not an objective.

## Error budgets

4. The budget is the complement of the target over a rolling window: 99.5% availability over 30 days ≈ 3.6 hours of failure to spend.
5. **Burn alerts, not threshold alerts:** alert when the budget is burning fast (e.g. >2% of monthly budget in an hour), which catches both hard outages and slow bleeds (`observability.md` rule 11).

## When the budget burns

6. **Budget healthy** → ship features at full speed. The budget exists to be spent; 100% reliability is over-investment.
7. **Budget exhausted (or burning hot)** → the next unit of work is reliability work, not features: fix the regression, add the missing guard, finish the runbook that didn't exist. This trade is the entire point of the mechanism — it converts "should I harden or build?" from a feeling into a rule.
8. Repeated burns from the same cause escalate to an ADR-level decision (different host box, different design) rather than a third patch (`00-governance/standards-lifecycle.md` feedback loop).

## Review cadence

9. Glance at budget status when releasing (`06-delivery/release-process.md` step 4); review SLO targets quarterly — targets that are never threatened are too loose, targets always in breach are dishonest.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this change can move a user-facing SLI (latency, availability, error rate), state the expected impact on the SLO in the PR description.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (SLOs are set per project once real traffic exists; this doc is the recipe).
