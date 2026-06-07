# Code Review Standard — the AI Self-Review Checklist

The solo developer's stand-in for a second reviewer. Before any work is declared done, the author — and in this workflow the author is usually an AI agent — runs this checklist **against the full diff**, item by item. Each item gets one of: *pass*, *fixed*, or *justified miss* (recorded in the PR's self-review notes). Skipping the run and claiming done is a process violation (`00-governance/agent-operating-rules.md` §6).

- Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss.

## A. Correctness & scope

- [ ] The diff does what the task says — re-read the spec/issue last, then the diff; they still agree.
- [ ] Edge cases that the diff's logic implies (empty, null/undefined, zero, duplicate, concurrent, unauthorized) are handled or consciously out of scope.
- [ ] No invented APIs: every imported symbol, config key, env var, and route referenced actually exists in the repo or its dependencies.
- [ ] Error paths act sensibly: nothing swallowed, failures surface where they can be acted on.
- [ ] No unrelated drive-by changes — they belong in their own PR.

## B. Tests & verification

- [ ] Each behavioral change has a test that fails without the change (mentally re-run: would this test have caught the bug/absence?).
- [ ] Tests assert behavior, not implementation; no assertion-free or snapshot-only "coverage".
- [ ] Anything the test runner cannot reach (async server-rendered paths per the stack ADR) is covered at the E2E tier or flagged.
- [ ] The change was actually run (tests locally, or the preview deploy eyeballed for UI changes) — not assumed to work.

## C. Security & data

- [ ] All new external input is schema-validated at the boundary.
- [ ] No secrets, tokens, or real env values anywhere in the diff; nothing sensitive added to logs or error messages.
- [ ] Session/permission checks happen at the handler/component that serves the data — never only in middleware (governance guardrail 3).
- [ ] DB changes are new forward-only migration files; no applied migration touched.

## D. Code quality

- [ ] Names come from the glossary; new concepts got glossary entries.
- [ ] The diff matches surrounding idiom; no new pattern introduced where an existing one fits.
- [ ] No suppressed diagnostics, loosened configs, or weakened gates introduced to get to green.
- [ ] No dead code, debug output, or commented-out blocks left behind.

## E. Aggregated fallback checks

Each line below is the verbatim `Fallback if unenforceable` from a layer doc whose enforcement mechanism is `none-possible` — this checklist is their only gate. Source doc in parentheses.

- [ ] Confirm the diff stays within the approved spec's scope and non-goals; name any scope creep explicitly and split it out. (`02-product/spec.template.md`)
- [ ] Every acceptance criterion for this task maps to at least one automated test or a named manual verification step. (`02-product/acceptance-criteria.md`)
- [ ] For changes touching auth, session, input parsing, file handling, or data access: confirm the feature's threat model exists and each listed mitigation is implemented in this diff. (`03-design/threat-model.template.md`)
- [ ] Confirm the change ships through the standard promotion flow (PR → preview → production) with no manual host-side steps introduced. (`06-delivery/deployment-strategy.md`)
- [ ] State the rollback path for this change (revert commit, feature-flag off, or roll-forward migration) in the PR description before merging. (`06-delivery/rollback.md`)
- [ ] New or changed code paths emit structured logs with event name and context fields per the logging convention; no stray console debugging remains. (`07-operations/observability.md`)
- [ ] If this change alters detection, mitigation, or recovery behavior, update the affected incident runbook in the same PR. (`07-operations/incident-runbook.template.md`)
- [ ] If this change can move a user-facing SLI (latency, availability, error rate), state the expected impact on the SLO in the PR description. (`07-operations/slo-error-budgets.md`)
- [ ] Every shortcut taken in this diff is recorded in the debt log with a paydown trigger; none are silent. (`08-maintenance/tech-debt-policy.md`)
- [ ] If this change deprecates an API, route, flag, or schema field, it adds the deprecation marker and migration note instead of deleting outright. (`08-maintenance/deprecation-process.md`)
- [ ] Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss. (this doc)

Maintenance rule: when any layer doc adds or edits a `none-possible` fallback line, this section changes **in the same commit** (root `CLAUDE.md` §1); `scripts/audit-completeness.sh` and the lifecycle process keep the two from drifting.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the project `CLAUDE.md` links here; the injected PR template requires the self-review checkbox).
