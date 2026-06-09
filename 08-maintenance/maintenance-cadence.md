# Maintenance Cadence

Upkeep that happens reactively happens in a panic — a CVE on a Friday, a restore that's never run, a six-month dependency gap discovered as a migration project. The cure is rhythm: a small set of recurring obligations a solo-plus-AI operator can **batch on a predictable heartbeat** rather than rediscover under pressure. This doc owns no cadences of its own — it is a consolidating map that points at where each interval is defined, so the operator has one place to see the whole loop and no place where a number can drift. Every numeric interval below is owned by the standard linked in its row; change it there, not here.

## The cadence map

Each obligation is owned by exactly one standard, which carries its interval, its rationale, and its enforcement. This table is the index, not the source of truth for any value.

| Interval | Activity | Owned by |
|---|---|---|
| Continuous (per change) | Leave each touched module marginally cleaner; log any shortcut taken in the same diff | `08-maintenance/tech-debt-policy.md` |
| Per release | State the rollback path for the change in the PR before merge | `06-delivery/rollback.md` |
| Weekly | Process the grouped automated dependency-update PRs (minor/patch batched, majors individual) | `08-maintenance/dependency-updates.md` |
| Immediate (out of band) | Review and land a security-fix update the day it opens, outside the weekly rhythm | `08-maintenance/dependency-updates.md`, `04-build/dependency-policy.md` |
| Monthly | Restore the latest backup into a scratch DB and assert invariants | `07-operations/backup-dr.md` |
| Per destructive migration | Run the same restore verification *before* the migration ships | `07-operations/backup-dr.md`, `06-delivery/migration-discipline.md` |
| Quarterly | Sweep the debt log (close paid, escalate grown, re-confirm "accepted permanently") | `08-maintenance/tech-debt-policy.md` |
| Quarterly | Prune unimported dependencies; review accepted-risk pins for expiry | `04-build/dependency-policy.md` |
| Quarterly | Exercise the rollback drill on production with a no-op release | `06-delivery/rollback.md` |
| Twice-yearly | Currency pass: re-verify time-sensitive pinned decisions and dated guardrails; harvest flow-back; walk data-touched calibration knobs | `00-governance/standards-lifecycle.md` |

## How to run the loop

1. **The map is read-only for values.** This doc never restates an interval as a number — it names the activity and points at the owner. A reader who wants the exact frequency, the rationale, or the enforcement gate follows the link. This keeps the heartbeat in one viewable place without creating a second copy of every cadence to drift against.
2. **Batch by interval, not by category.** The point of a shared rhythm is that same-interval work is done together: the weekly pass clears update PRs in one sitting; the quarterly pass does the debt sweep, the dependency prune, and the rollback drill as one block. Batching is what turns a list of obligations into a routine an operator actually keeps.
3. **The continuous tier is invisible and constant.** Module-cleanliness-on-touch and shortcut-logging-in-the-diff aren't scheduled — they ride every change. They are on the map so the operator sees that the smallest, most frequent maintenance is already accounted for and needs no separate slot.
4. **Out-of-band obligations break the rhythm on purpose.** Security patches and pre-destructive-migration restore checks are event-triggered, not interval-triggered; they preempt the batch when their event fires. The map distinguishes them so they're never mistaken for work that can wait for the next scheduled window.
5. **A new recurring obligation joins the map but is owned by its standard.** When a new repeating maintenance duty appears, its interval, rationale, and enforcement are defined in the standard that owns the activity; only a pointer row is added here. This doc must never become the place a cadence is invented or its value lives — that is what would let the map and the owners disagree.

## Standards basis

- **DORA / Accelerate — small batches and reduced batch size** (dora.dev; Forsgren, Humble, Kim, *Accelerate*) — working in small, frequent batches lowers risk and rework versus large infrequent ones; the elite-performer pattern is continuous, consistent flow rather than episodic catch-up. The weekly/quarterly heartbeat applies that finding to upkeep: many tiny, regular maintenance increments beat occasional large ones, and a consistent cadence is itself a measured driver of delivery performance.
- **The Boy Scout Rule** (Robert C. Martin, *Clean Code*; orig. Baden-Powell, "leave it better than you found it") — leave each module marginally cleaner than found, as a continuous habit rather than a scheduled cleanup phase. This is the basis for the continuous (per-change) tier of the map; the standing interleave it implies is owned and quantified by `08-maintenance/tech-debt-policy.md`, not restated here.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Any new recurring-maintenance obligation is added to the cadence map as a pointer row whose interval and rationale are owned by its source standard — never invented or numerically defined in this doc.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the cadences this map indexes are injected by their owning standards: the update bot config, the nightly restore-test workflow, the debt-log starter, and the PR template's rollback section).
