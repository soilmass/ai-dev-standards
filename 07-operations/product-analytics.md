# Product Analytics, RUM & Metrics

`07-operations/observability.md` covers whether the system is *healthy*; this doc covers whether the product is *working* — the events, real-user performance, and success metrics that tell you if anyone is getting value. It is the same telemetry discipline pointed at the user instead of the server, and it is bound by the same privacy rules: analytics is a notorious place for PII to leak.

## Event taxonomy

1. **Define the event before you fire it.** Each tracked event has a registered name (`snake_case` verb-object: `signup_completed`, `checkout_started`), a stable set of typed properties, and a one-line purpose. The registry is a `docs/analytics-events.md` table (event → properties → purpose → owner) — an event nobody documented is an event nobody can trust or query.
2. **Name events for what the user did, not for the UI that did it.** `checkout_completed` survives a redesign; `blue_button_clicked` does not. Track the outcome, so the metric stays comparable across releases.
3. **Instrument the funnel, not the firehose.** Track the steps of the journeys that define success (the same revenue-critical paths the E2E crown guards, `04-build/testing-strategy.md`) plus the activation/retention moments — not every click. Volume without a question to answer is cost and noise; each event should map to a decision someone will actually make.
4. **Version the schema; never silently repurpose an event.** Adding a property is additive. Changing the meaning of an existing event or property is a breaking analytics change — give it a new name or version, the same discipline as `03-design/api-evolution.md`, or every historical comparison quietly lies.

## Privacy is not optional in analytics

5. **Identify users by opaque ID, never by PII.** No email, name, phone, or precise location in event properties, user traits, or the analytics URL (`07-operations/observability.md` rule 5, `03-design/data-privacy.md` rule 7). The analytics store is a third-party processor and a breach surface; treat every property as something that could leak.
6. **Analytics needs a lawful basis, and usually consent.** Non-essential analytics/tracking cookies and device fingerprinting require prior opt-in consent under the ePrivacy Directive and GDPR (Arts. 6–7); honor it (no firing before consent, honor Do-Not-Track/Global-Privacy-Control where applicable) and record the basis. "We measure everything by default" is a compliance finding, not a strategy.
7. **Analytics data is in scope for DSR and retention.** A user's analytics records are part of "all their data" for access/erasure (`03-design/data-privacy.md` rules 8, 12) — which is only tractable *because* of rule 5 (opaque ID lets you find and delete them). Set a retention period on raw event data; aggregates can outlive the raw rows.

## Real-user monitoring (RUM)

8. **Collect Core Web Vitals from the field, at p75.** LCP, INP (the responsiveness metric that replaced FID in 2024), and CLS measured on real sessions are the truth the lab budgets in `05-verification/a11y-perf-gates.md` only approximate. Report via the framework's built-in vitals hook into the same pipeline — no second SDK to start (`07-operations/observability.md` rule 10).
9. **The lab gate and the field metric are reviewed together.** When SLOs are set (`docs/slos.md`), compare field p75 against the same thresholds that gate CI; a green Lighthouse run with a failing field p75 means the lab conditions don't match real users (device, network, geography) and the budget or the form factor needs revisiting (calibration CAL-C02/C09).
10. **Segment RUM by device and connection.** A healthy median hides a broken slow-3G/low-end-mobile tail — which, since the gate runs mobile-first, is exactly the population that matters most. Aggregate-only RUM is a vanity metric.

## Metrics that drive decisions

11. **Pick a small set of success metrics and emit them as events from day one.** The business outcomes that define "working" (sign-ups, activations, checkouts, retention) are events from the first release — the SLOs and error-budget policy depend on them (`07-operations/slo-error-budgets.md`), and you cannot backfill a metric you never recorded.
12. **Tie each metric to a target and a review cadence, or drop it.** A number on a dashboard that nobody compares to an expectation changes no behavior. Each tracked success metric has an owner, an expected direction, and a place it is reviewed (the same quarterly rhythm as the SLO and debt reviews) — and a metric that has driven no decision in two reviews is a candidate for deletion, same as a dead alert.

## Standards basis

- **Core Web Vitals — field measurement at p75** (web.dev/articles/vitals): **LCP**, **INP** (replaced FID as the Core responsiveness metric in March 2024), and **CLS**, measured from real users at the 75th percentile — the methodology behind rules 8–10. The lab/field distinction is web.dev's own.
- **W3C Web Performance — Navigation Timing, Event Timing, Layout Instability** (w3.org/webperf) and the **`web-vitals` library**: the browser APIs that produce field CWV; grounds the "framework's built-in vitals hook" of rule 8.
- **GDPR Arts. 5–7 + ePrivacy Directive 2002/58/EC (Art. 5(3), the "cookie" rule)**: lawful basis and prior consent for non-essential tracking; the basis for rules 5–7. **EDPB guidance on consent** corroborates opt-in-before-firing.
- **Global Privacy Control / Do Not Track** (globalprivacycontrol.org): a machine-readable opt-out signal rule 6 says to honor where applicable.
- **Pirate metrics / AARRR (Acquisition, Activation, Retention, Referral, Revenue)** (Dave McClure) and the **North Star Metric** framing: the product-analytics lens behind rules 3 and 11 — instrument the funnel that defines value, anchor on a small metric set. Used as a framing, not a mandate.
- Extends `07-operations/observability.md` (RUM/client-error wiring floor; this doc owns the product-event and success-metric side) and is bound by `03-design/data-privacy.md` (classification, retention, DSR) and `_spines/security-privacy.md` (opaque-ID logging).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: New tracked events are registered (name, typed properties, purpose) and identify users by opaque ID only — no PII in properties, traits, or URLs — fire only after any required consent, and carry a retention period; success metrics emitted from day one each have a target and a review home.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the analytics/RUM vendor is a per-project choice recorded as an ADR; the framework's field-vitals hook and the consent mechanism are wired per project).
