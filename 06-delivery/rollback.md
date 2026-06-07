# Rollback

The procedure for undoing a bad release — written down *now* because mid-incident is the worst time to design it. Every PR states which of these paths applies to it (the PR template requires it).

## The three rollback paths

Ordered by speed; use the fastest one that fits the failure.

1. **Flag off (seconds).** If the change is behind a feature flag, turn it off. This is why risky changes ship flagged (`06-delivery/release-process.md`).
2. **Redeploy previous build (minutes).** The host keeps prior builds warm; promote the last good deploy. Works for any code-only regression — this is the default path.
3. **Revert commit (minutes–hours).** `git revert` the offending commit(s) on `main`, let the pipeline deploy the revert. Use when the bad change is entangled with later merges or the host-level rollback isn't clean. Never force-push history to "remove" the bad commit (`04-build/git-standards.md`).

## The hard case: data

4. **Migrations don't roll back — they roll forward** (`06-delivery/migration-discipline.md`). If a deploy included a migration:
   - Code-only regression → paths 1–2 still work *only if* the old code runs against the new schema — which the expand→migrate→contract rule exists to guarantee.
   - Bad migration itself → write a corrective forward migration. If data was destroyed, restore from backup (`07-operations/backup-dr.md`) and reconcile the gap; this is an incident (`07-operations/incident-runbook.template.md`).
5. This is why destructive schema changes are released in a separate contract phase: it keeps path 2 available for everything else.

## Kill-switch inventory

6. Every risky external integration (payments, email, third-party APIs) sits behind a config kill switch that degrades gracefully. The switches and their behavior are listed in the project's architecture map ("external dependencies" table — failure mode column).

## Drill

7. Once per quarter (or before the first real launch), actually exercise path 2 on production with a no-op release: promote previous build, verify, re-promote. A rollback procedure that has never run is a hypothesis, not a procedure.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: State the rollback path for this change (revert commit, feature-flag off, or roll-forward migration) in the PR description before merging.

## Bootstrap
- What new-project.sh injects for this standard: the PR template with the required "Rollback path" section.
