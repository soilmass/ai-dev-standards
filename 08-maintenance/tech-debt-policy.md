# Tech Debt Policy

Debt is a tool: borrowing speed against future work is sometimes right. Unmanaged debt is not a tool — it's entropy with interest. The policy: every borrow is **logged, visible, and has a paydown trigger**.

## The debt log

1. The project keeps a debt log — `docs/debt-log.md` (starter injected at bootstrap from `debt-log.template.md`), one table:

   | ID | Date | What was shortcut | Why | Cost when it bites | Paydown trigger | Status |
   |---|---|---|---|---|---|---|

2. **Every shortcut gets a row at the moment it's taken** — in the same PR that takes it. "Shortcut" means: a known-worse design chosen for speed, a skipped edge case, a copy-paste pending the third-use extraction, a flag overdue for removal, an accepted-risk dependency pin.
3. The *paydown trigger* is concrete: "before adding a second payment provider", "when this table passes 1M rows", "next time this module is touched" — not "someday". A debt with no trigger is a decision to never pay; make that explicit by writing "accepted permanently" and the reason.
4. Agents: any shortcut you take goes in the log in the same diff (self-review checklist enforces this); proposing a shortcut is fine, hiding one is not.

## Paying it down

5. **Triggered debt blocks the triggering work**: when a PR's scope hits a debt row's trigger, the paydown happens first (or in the same PR if small). This is what makes triggers real.
6. Standing budget: roughly **10–20% of work** goes to debt paydown and maintenance, naturally interleaved — the "next time this module is touched" triggers do most of this automatically.
7. Error-budget exhaustion overrides feature work entirely (`07-operations/slo-error-budgets.md` rule 7) — reliability debt is debt with a margin call.
8. Quarterly, sweep the log: close paid rows, escalate rows whose cost estimate grew (an ADR or a spec), re-confirm "accepted permanently" rows still deserve it.

## What is not debt

9. Bugs are bugs (fix or ticket them), and missing tests for shipped behavior are a definition-of-done violation, not debt. The log tracks *chosen* tradeoffs — calling defects "debt" launders them.

## Standards basis
- **Fowler, Technical Debt Quadrant** (martinfowler.com/bliki/TechnicalDebtQuadrant.html) — debt is two axes, deliberate↔inadvertent and prudent↔reckless; only *deliberate-prudent* ("ship now, pay later, knowingly") is a legitimate tool. The debt log captures exactly this quadrant — a logged shortcut with a reason and a paydown trigger is deliberate-prudent by construction; an unlogged one is reckless. Inadvertent-prudent debt ("now we know how it should've been done") is logged when discovered, same row.
- **Fowler, Technical Debt** (martinfowler.com/bliki/TechnicalDebt.html) — the interest metaphor: unpaid debt accrues cost ("cost when it bites"); paying down where the code is being touched anyway minimizes that interest, which rule 6's interleave-on-touch implements.
- **The Boy Scout Rule** (Robert C. Martin, *Clean Code*; orig. Baden-Powell, "leave it better than you found it") — leave each module marginally cleaner than found; this is the mechanism behind the "next time this module is touched" trigger and the standing 10–20% interleave, not a separate cleanup phase.
- **Google SRE — error budgets** (sre.google/sre-book) — when the reliability budget is exhausted, reliability work preempts features; rule 7 treats that as a margin call on reliability debt.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every shortcut taken in this diff is recorded in the debt log with a paydown trigger; none are silent.

## Bootstrap
- What new-project.sh injects for this standard: `docs/debt-log.md` (from `debt-log.template.md`) — rows accrue from the first shortcut; this doc defines the policy around it.
