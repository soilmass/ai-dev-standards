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

## Retiring a public API (the no-rollback case)

8. A removed endpoint can't be "rolled back" for clients that already depend on it — withdrawal is a forward, announced process, never a silent break. When an externally-consumed API or route is being retired, signal it on the response *before* it disappears: a `Deprecation` header (with the optional `Link rel="deprecation"` to migration docs) once it's no longer preferred, then a `Sunset` header naming the date it stops responding. After the sunset date, respond `410 Gone`. This is the contract-phase analogue of expand→contract for HTTP surfaces.

## Drill

9. Once per quarter (or before the first real launch), actually exercise path 2 on production with a no-op release: promote previous build, verify, re-promote. A rollback procedure that has never run is a hypothesis, not a procedure.

## Standards basis

- **DORA failed-deployment recovery time** (dora.dev/guides/dora-metrics) — speed of restoring service after a deployment-caused failure is a primary delivery-performance dimension (reframed toward throughput in the 2024–25 model). Aligns: paths are ordered fastest-first; the drill keeps recovery time real, not hypothetical.
- **Forward-only / roll-forward recovery** (evolutionary DB practice) — data changes recover by corrective forward migration or verified restore, not by reversing applied migrations. Aligns: §4–5.
- **Expand–contract / Parallel Change** (Fowler, martinfowler.com/bliki/ParallelChange.html) — keeping old code schema-compatible is what makes redeploy-previous (path 2) safe across a migration. Aligns: §4 bullet 1, §5.
- **RFC 8594 — The Sunset HTTP Header Field** (datatracker.ietf.org/doc/html/rfc8594) — advertises the point at which a URI becomes unresponsive, plus a `sunset` link relation. Basis for §8's sunset signaling.
- **RFC 9745 — The Deprecation HTTP Response Header Field** (Standards Track, March 2025; datatracker.ietf.org/doc/rfc9745/) — signals that a resource is or will be deprecated and links to migration guidance; pairs with `Sunset`. Basis for §8's deprecation signaling.
- **RFC 9110 §15.5.9 — `410 Gone`** (datatracker.ietf.org/doc/html/rfc9110) — the defined status for a resource intentionally and permanently removed. Aligns: §8's post-sunset response.
- **Immutable history on rollback** (git practice; no rewriting shared history) — reverts add commits, they don't erase them. Aligns: §3's no-force-push rule.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: State the rollback path for this change (revert commit, feature-flag off, or roll-forward migration) in the PR description before merging.

## Bootstrap
- What new-project.sh injects for this standard: the PR template with the required "Rollback path" section.
