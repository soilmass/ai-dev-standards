# Backups & Disaster Recovery

A backup that has never been restored is a wish. This doc sets the cadence and — the part that actually matters — the restore-verification rule.

## What gets backed up

1. **The database** — the only state that can't be rebuilt. Code is in git; builds are reproducible; the host is re-creatable from config. If the project stores user uploads, those join the list.
2. Managed-DB automatic backups (the stack's box-3 host provides them) are the baseline, **plus** a periodic logical dump to storage the DB provider doesn't control — provider-internal backups don't cover account-level failures (billing lockout, account compromise, provider exit).

## Cadence & retention

3. Continuous/daily automatic backups per the provider, with point-in-time recovery enabled where offered.
4. Logical dump at least daily for active projects; retention ladder: 7 daily, 4 weekly, 12 monthly — enough to recover from corruption discovered late.
5. Backup failures alert (a silent backup gap is itself an incident).

## The restore-verification rule

6. **A backup counts only after a restore of it has succeeded.** On cadence (monthly, and before any destructive migration per `06-delivery/migration-discipline.md` rule 7): restore the latest backup into a scratch database and assert invariants — row counts within expected range, critical tables present, a known record intact.
7. Wire the assertion as the project's `restore:verify` script; the nightly pipeline runs it (`05-verification/ci-pipeline.md`). The script must exist and do a real restore before production data exists — afterward is too late to find out the dumps were empty.
8. Record each verified restore (date, backup ID, duration) in the ops log; the restore *duration* is your real RTO, not the number you hoped.

## Disaster recovery targets

9. Declare two numbers in `docs/slos.md` alongside the SLOs:
   - **RPO** (max acceptable data loss): bounded by backup frequency — daily dumps mean accepting up to a day; tighten with PITR if that's unacceptable.
   - **RTO** (max acceptable downtime): bounded by measured restore duration + redeploy time.
10. The full-loss drill (provider account gone): restore the external dump to a fresh DB, point a fresh deploy at it, verify. Run it once before launch; its steps become an incident runbook (`incident-runbook.template.md`).

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/nightly.yml (restore-test job runs the project's `restore:verify` script)
- Fallback if unenforceable: n/a — restore verification is pipeline-run once the project wires `restore:verify`; rule 7 makes wiring it a pre-production requirement, checked at release via the definition of done's preview/ops items.

## Bootstrap
- What new-project.sh injects for this standard: the nightly workflow containing the restore-test job (the project supplies its `restore:verify` script).
