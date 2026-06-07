# SLOs — <PROJECT_NAME>

> Dropped at bootstrap as `docs/slos.md`. Fill it once real traffic exists (method: `07-operations/slo-error-budgets.md` — measure a month, set targets slightly above reality). Keep it to 2–3 SLIs; review quarterly.

- **Window for all SLOs:** rolling <30_DAYS_OR_OTHER>
- **Last reviewed:** <YYYY-MM-DD>

## Service-level objectives

| SLI | Definition (measurable) | Target | Error budget / window | Burn alert at |
|---|---|---|---|---|
| Availability | <NON_5XX_SHARE_OF_REQUESTS_ON_WHICH_ROUTES> | <99.5%> | <3.6_HOURS> | <2%_OF_BUDGET_IN_1H> |
| Latency | <SHARE_OF_REQUESTS_UNDER_THRESHOLD_E_G_P95_LT_500MS> | <TARGET> | <BUDGET> | <BURN_RATE> |
| <JOURNEY_SLI_OR_DELETE_ROW> | <E_G_CHECKOUT_COMPLETES_WITHIN_10S_OF_SUBMIT> | <TARGET> | <BUDGET> | <BURN_RATE> |

**When the budget exhausts:** the next unit of work is reliability work, not features (`slo-error-budgets.md` rule 7).

## Disaster-recovery targets (`07-operations/backup-dr.md` rule 9)

| Target | Value | Bounded by |
|---|---|---|
| RPO (max data loss) | <E_G_24H> | backup frequency: <CADENCE> |
| RTO (max downtime) | <E_G_4H> | measured restore duration (<LAST_MEASURED>) + redeploy time |

## Verified-restore log

| Date | Backup ID | Restore duration | Invariants checked | OK? |
|---|---|---|---|---|
| <YYYY-MM-DD> | <ID> | <DURATION> | <ROW_COUNTS_CRITICAL_TABLES_KNOWN_RECORD> | <YES_NO> |

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this change can move a user-facing SLI (latency, availability, error rate), state the expected impact on the SLO in the PR description.

## Bootstrap
- What new-project.sh injects for this standard: this template as `docs/slos.md` — filled in once the project has a month of real traffic.
