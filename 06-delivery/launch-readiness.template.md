<!-- docs/launch-readiness.md — the go/no-go review before first production launch
(and before any launch-significant change). Standard: 06-delivery/launch-readiness.md.
Mark each item pass / fail / n-a (with reason). A fail on a load-bearing item blocks
launch OR is recorded below as a signed risk acceptance. Commit the completed file. -->

# Launch Readiness Review — <PROJECT / LAUNCH NAME>

- **Date:** <YYYY-MM-DD>
- **Decision:** <GO | NO-GO | GO-WITH-ACCEPTED-RISKS>
- **Reviewer:** <NAME>

## 1. Reliability
- [ ] SLOs declared from a measured baseline (`docs/slos.md`); error-budget policy set
- [ ] Backup taken **and a restore verified** (not just configured)
- [ ] Rollback path proven by a drill (flag-off / redeploy / revert)
- [ ] Incident runbook exists; alerts page a real destination

## 2. Security & privacy
- [ ] Threat model done for launch-critical features; mitigations implemented
- [ ] No secrets in the repo; env is boot-validated
- [ ] Dependency audit + supply-chain (SBOM/provenance) gates green
- [ ] PII classified; DSR (export/erase) and retention satisfiable

## 3. Quality
- [ ] Full CI + nightly tier green on the release commit
- [ ] Performance budgets pass; load test clears the latency SLO (if applicable)
- [ ] Accessibility gate green

## 4. Delivery
- [ ] Deploy and rollback rehearsed
- [ ] Risky surfaces behind flags / kill-switches
- [ ] Release + changelog process works; branch + tag protection + required checks on

## 5. Compliance (if in scope)
- [ ] Controls + evidence in place for the launch scope

## Accepted risks (for any item marked fail)
| Item | Risk | Why accepted | Owner | Revisit by |
|---|---|---|---|---|
| <ITEM> | <RISK> | <REASON> | <NAME> | <YYYY-MM-DD> |

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Before first production launch (or a launch-significant change — new region, new data class, major rearchitecture), the launch-readiness checklist passes: SLOs + error-budget set, a backup restore-verified, rollback drilled, runbook + alerting wired, threat model done, secrets/deps/supply-chain green, perf + a11y (+ load where applicable) gates green, branch/tag protection on — with any fail recorded as a signed risk acceptance.

## Bootstrap
- What new-project.sh injects for this standard: this template as `docs/launch-readiness.md` — the go/no-go checklist to complete before launch.
