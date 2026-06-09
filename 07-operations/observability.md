# Observability

You can't operate what you can't see. This doc sets the conventions for logs, metrics, traces, alerting, and — the cell solo projects most often skip — client-side error tracking and real-user monitoring.

## Structured logging convention

1. All server logs are **structured** (JSON), through one logger module — never bare console output in production code (lint-enforced).
2. Every log line carries: `event` (machine-readable snake_case name — the log's primary key for querying), `level`, timestamp, and a request/correlation ID propagated through the request's lifetime.
3. Context goes in **fields, not prose**: `{"event": "checkout_failed", "order_id": …, "reason": …}` — not a sentence with values interpolated into it.
4. Levels mean something: `error` = needs action, `warn` = unexpected but handled, `info` = business-relevant event, `debug` = local diagnosis (never on in production).
5. **Never log**: secrets, tokens, passwords, full PII records, raw request bodies that may contain any of those. Identify users by ID, not by email/name (`_spines/security-privacy.md`).

## Metrics

6. The minimum panel for any web app: request rate, error rate, latency percentiles (p50/p95/p99) per route, and the saturation of whatever the platform meters (function duration, DB connections).
7. Business metrics that define success (sign-ups, checkouts) are emitted as events from day one — the SLOs in `slo-error-budgets.md` need them.

## Tracing

8. Propagate the correlation ID across every boundary (frontend → API → DB/external calls) using the **W3C Trace Context** `traceparent`/`tracestate` headers — the vendor-neutral propagation format, so the trace stitches together no matter which backend reads it. Adopt distributed tracing tooling when more than one service exists — until then, the correlated logs ARE the trace.

## Client-side error tracking & real-user monitoring

9. **Required, not optional**: an error-tracking SDK captures unhandled exceptions and rejections in the browser. The server being green while every client throws is the classic silent failure. The vendor is a per-project choice (recorded as an ADR); whatever is chosen, the wiring floor is:
   - **Both global hooks covered** — uncaught exceptions *and* unhandled promise rejections — plus the framework's root error boundary reporting into the same SDK (an error boundary that only renders a sad face swallows the signal).
   - **Source maps uploaded per release and events tagged with the release/commit ID** — an unsymbolicated minified stack is noise, and untagged events can't answer "did the last deploy cause this?".
   - **User-impact counts, not raw event counts**, drive triage: 1 error × 10,000 users outranks 10,000 errors × 1 user.
   - The SDK's redaction config upholds rule 5 (no PII/secrets in error payloads — scrub URLs, form values, request bodies).
10. Real-user monitoring collects Core Web Vitals **from the field**, reported through the framework's built-in vitals hook into the analytics/error pipeline (no second SDK needed to start). The lab budgets in `05-verification/a11y-perf-gates.md` are gates; field data is the truth they approximate — review field p75 against the same thresholds when SLOs are set (`docs/slos.md`). The product-event taxonomy and success-metric side of this telemetry — including the RUM segmentation discipline — lives in `07-operations/product-analytics.md`.

## Alerting

11. Alert on **symptoms users feel** (error-budget burn, elevated 5xx, p95 over threshold, client error spikes), not on causes (CPU). Every alert is actionable and links a runbook (`incident-runbook.template.md`); an alert that's routinely ignored gets fixed or deleted.

## Standards basis
- **Google SRE — Four Golden Signals** (latency, traffic, errors, saturation; *SRE* book, "Monitoring Distributed Systems", https://sre.google/sre-book/monitoring-distributed-systems/): the minimum user-facing telemetry set — rule 6's metrics floor maps directly (request rate = traffic, error rate = errors, latency percentiles = latency, platform meter = saturation).
- **RED method** (Rate/Errors/Duration; Wilkie, request-scoped, per-service) and **USE method** (Utilization/Saturation/Errors; Gregg, resource-scoped): complementary lenses — RED frames rules 6–7's per-route service view, USE frames the saturation/resource view. The two are explicitly meant to be used together.
- **OpenTelemetry** (https://opentelemetry.io/docs/concepts/signals/): the vendor-neutral signal model — traces and logs are stable specs, metrics data model stable via OTLP. Grounds rules 6–8 treating logs/metrics/traces as one correlated telemetry fabric and the "adopt distributed tracing tooling" guidance.
- **W3C Trace Context** (Recommendation, https://www.w3.org/TR/trace-context/): standard `traceparent`/`tracestate` HTTP headers for cross-boundary context propagation — the concrete standard behind rule 8's correlation-ID propagation.
- **Structured logging** (machine-parseable key/value events): rules 1–4 — `event` as primary key, context in fields not prose, levels with defined semantics — are the accepted structured-logging discipline that makes logs queryable telemetry rather than text.
- **Core Web Vitals** (field-measured: LCP, INP — which replaced FID as the responsiveness metric in 2024 — and CLS): rule 10's real-user monitoring collects these from the field at p75, the threshold percentile the methodology defines.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: New or changed code paths emit structured logs with event name and context fields per the logging convention; no stray console debugging remains.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the lint config's console ban is injected via the preset and covers rule 1's mechanical half).
