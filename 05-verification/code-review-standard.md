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
- [ ] This item meets the lightweight readiness heuristics before starting, and is closed as Done only when every acceptance criterion passes and the user-visible outcome holds end-to-end across all its merged PRs. (`02-product/definition-of-ready-done.md`)
- [ ] If this PR changes an externally-consumed API, it states whether the change is additive (MINOR) or breaking (MAJOR), and any breaking change ships a new major version in parallel and signals retirement of the old via Deprecation → Sunset → 410 rather than removing it in place. (`03-design/api-evolution.md`)
- [ ] Every custom composite widget (combobox, dialog, menu/menubar, tabs, disclosure, listbox) implements its full APG keyboard contract — expected keys, single tab stop (roving tabindex or aria-activedescendant, not both), correct ARIA roles/states, and dialog focus trap + focus-return — verified by keyboard-only walkthrough; no native element would have sufficed. (`03-design/ui-accessibility-patterns.md`)
- [ ] For a change touching a trust boundary, asset, or entry point (auth, sessions, money, secrets, PII, file handling, new input surface), confirm a threat model exists per `03-design/threat-modeling.md`, every kept threat has a response with a verification location, and the diff implements those mitigations. (`03-design/threat-modeling.md`)
- [ ] Every PII/payment field has a recorded class, a named purpose, and a retention entry; erasure and export paths exist and are tested for it (no soft-delete-only PII table); DSR requests are authenticated, scoped via the PII map, and answered within one month. (`03-design/data-privacy.md`)
- [ ] If this change adds or alters an alert, confirm the alert is symptom-based, actionable, and links a runbook with a defined escalation step; if it removes a failure mode, retire the now-dead alert in the same PR. (`07-operations/oncall-escalation.md`)
- [ ] If the error budget is exhausted or burning at the page tier, confirm this change is reliability, P0, or security work — or a recorded silver-bullet exception — and not a feature shipped during a freeze. (`07-operations/error-budget-policy.md`)
- [ ] Every publicly reachable mutating or expensive endpoint declares a rate-limit strategy keyed to the right identity (account before IP), returns 429 with Retry-After on over-limit, and bounds request size/cost at the boundary; auth endpoints additionally carry anti-automation controls named in the feature's threat model. (`03-design/rate-limiting-abuse.md`)
- [ ] New tracked events are registered (name, typed properties, purpose) and identify users by opaque ID only — no PII in properties, traits, or URLs — fire only after any required consent, and carry a retention period; success metrics emitted from day one each have a target and a review home. (`07-operations/product-analytics.md`)
- [ ] Each third-party runtime integration is recorded as an ADR and in the architecture map with its data classification; every outbound call has a short timeout and a written blocking-vs-degrading fallback; retries are bounded/backed-off/idempotent; inbound webhooks are signature-verified and idempotent; keys are least-privilege env secrets; and removal runs through the deprecation process. (`04-build/third-party-integrations.md`)
- [ ] Security/trust-relevant actions emit append-only, tamper-evident audit records carrying actor/action+outcome/timestamp/source/target with no secrets or raw PII; the audit store has a different access boundary from what it audits; and each audit stream has an automated retention lifecycle with a defined minimum (binding requirement, ≥1y floor) and maximum. (`07-operations/audit-log-retention.md`)
- [ ] Expensive or metered operations (paid third-party/LLM calls, large exports, fan-out, email/SMS) carry a cost budget or limit at the boundary and emit an observable cost signal; new dependencies and paid integrations are justified against their cost; no endpoint is an uncapped denial-of-wallet surface. (`_spines/cost.md`)
- [ ] Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss. (this doc)

Maintenance rule: when any layer doc adds or edits a `none-possible` fallback line, this section changes **in the same commit** (root `CLAUDE.md` §1); `scripts/audit-completeness.sh` and the lifecycle process keep the two from drifting.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the project `CLAUDE.md` links here; the injected PR template requires the self-review checkbox).
