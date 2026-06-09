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
- [ ] Every acceptance criterion is Observable, Deterministic, and Atomic, and maps to at least one automated test or a named manual verification step. (`02-product/acceptance-criteria.md`)
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
- [ ] If a change affects local setup or onboarding, the one-command bootstrap still works — the pinned devcontainer/compose and the idempotent seed script are updated in the same change, and dev still mirrors prod's backing-service major. (`04-build/developer-experience.md`)
- [ ] If this change alters a hot path, capacity, or precedes launch or a known traffic event, run a load test (plus a soak before launch) and confirm the latency SLO and error budget hold at target load with headroom; record the measured knee and headroom. (`05-verification/load-testing.md`)
- [ ] If this change provisions or modifies infrastructure, it is declarative IaC in the repo with a reviewed plan (no console drift), state is remote/locked/encrypted with no secrets in state or source, and the change passed IaC misconfiguration scanning. (`06-delivery/infrastructure-as-code.md`)
- [ ] Before first production launch (or a launch-significant change — new region, new data class, major rearchitecture), the launch-readiness checklist passes: SLOs + error-budget set, a backup restore-verified, rollback drilled, runbook + alerting wired, threat model done, secrets/deps/supply-chain green, perf + a11y (+ load where applicable) gates green, branch/tag protection on — with any fail recorded as a signed risk acceptance. (`06-delivery/launch-readiness.md`)
- [ ] For a compliance-scoped change, confirm the affected control still holds and its evidence is captured by the running system (audit log, CI/PR history, SBOM, restore log, threat model) — not reconstructed later; any control the change cannot satisfy is recorded as an open gap with an owner. (`_spines/compliance.md`)
- [ ] This diff labeled a refactor preserves behavior and rides unchanged passing tests; anything touching the public API surface or rewriting test expectations is in its own revertible PR; cleanup stays within the touched footprint and untested targets got characterization tests first. (`04-build/refactoring-discipline.md`)
- [ ] Any new recurring-maintenance obligation is added to the cadence map as a pointer row whose interval and rationale are owned by its source standard — never invented or numerically defined in this doc. (`08-maintenance/maintenance-cadence.md`)
- [ ] Confirm no production secret has entered a local or preview environment, that preview/local use scoped non-production credentials against non-production data only, and that any rotated or newly required secret was applied to every environment its classification names so none silently diverge. (`06-delivery/secrets-promotion.md`)
- [ ] Every S1/S2 in this work has a blameless postmortem (systems and contributing factors, never individuals) covering timeline, detection, root vs contributing causes, what helped/hurt, and what would have caught it sooner; each action item is a tracked task or a debt-log row with an owner, and any detection/response gap is reflected back into the alerting and the runbook. (`07-operations/incident-postmortem.md`)
- [ ] Every public web surface ships HTTPS-only with HSTS, a default-deny Content-Security-Policy (frame-ancestors set, no `unsafe-inline`/`unsafe-eval` scripts), X-Content-Type-Options nosniff, and a minimized Referrer-Policy/Permissions-Policy; session/auth cookies are Secure + HttpOnly + SameSite; and every state-changing request not covered by SameSite carries a verified CSRF token. (`03-design/web-security-headers.md`)
- [ ] Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss. (this doc)

Maintenance rule: when any layer doc adds or edits a `none-possible` fallback line, this section changes **in the same commit** (root `CLAUDE.md` §1); `scripts/audit-completeness.sh` and the lifecycle process keep the two from drifting.

## Standards basis

- **Google Engineering Practices — Code Review Developer Guide** (google.github.io/eng-practices/review/) — separates *what to look for* (the standard) from the review *process*; its reviewer checklist (design, functionality, complexity, tests, naming, comments, consistency) maps onto §A–§D. The author-side "send small CLs / write good descriptions" guidance is why this checklist runs against a tight, one-concern diff.
- **Modern Code Review research** (SmartBear/Cisco study; Bacchelli & Bird, "Expectations, Outcomes, and Challenges of Modern Code Review", ICSE 2013) — review effectiveness drops sharply past ~200–400 LOC and ~60 minutes, and defect-finding is the secondary outcome after knowledge transfer / better solutions; grounds running this checklist on small diffs in one focused pass rather than continuously.
- **The author as first reviewer** (the self-review discipline; Fowler on self-testing code) — for a solo+AI workflow the author *is* the reviewer, so the checklist substitutes the second pair of eyes: re-read the spec, then the diff, as a deliberate separate act before declaring done.
- **Testing Library guiding principle** ("the more your tests resemble the way your software is used, the more confidence they give you") — the basis for §B's "assert behavior, not implementation".
- This doc is the aggregation point for every `none-possible` standard's fallback line (§E); each such line's own authority lives in its source doc's Standards basis, so this section grounds the *review act*, not the individual rules.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Run every item of this checklist against the full diff before declaring work done; fix or explicitly justify each miss.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the project `CLAUDE.md` links here; the injected PR template requires the self-review checkbox).
