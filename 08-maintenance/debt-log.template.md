# Debt Log — <PROJECT_NAME>

> Dropped at bootstrap as `docs/debt-log.md`. Every shortcut gets a row **in the same PR that takes it** (`08-maintenance/tech-debt-policy.md`). Triggered debt blocks the work that triggers it. Sweep quarterly: close paid rows, escalate grown ones, re-confirm "accepted permanently" rows.

| ID | Date | What was shortcut | Why | Cost when it bites | Paydown trigger | Status |
|---|---|---|---|---|---|---|
| D1 | <YYYY-MM-DD> | <THE_KNOWN_WORSE_CHOICE_TAKEN> | <THE_SPEED_REASON> | <WHAT_BREAKS_OR_SLOWS_LATER> | <CONCRETE_TRIGGER_E_G_BEFORE_SECOND_PROVIDER_OR_NEXT_TOUCH_OF_MODULE> | open |

Status values: `open` → `triggered` (trigger condition met — now blocking) → `paid` (close with the paying PR link), or `accepted permanently` (+ reason).

Reminder of what does NOT belong here: bugs (fix or ticket them) and missing tests for shipped behavior (definition-of-done violation) — the log tracks *chosen* tradeoffs only.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every shortcut taken in this diff is recorded in the debt log with a paydown trigger; none are silent.

## Bootstrap
- What new-project.sh injects for this standard: this template as `docs/debt-log.md` — rows accrue from the first shortcut.
