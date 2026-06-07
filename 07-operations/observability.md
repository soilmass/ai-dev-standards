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

8. Propagate the correlation ID across every boundary (frontend → API → DB/external calls); adopt distributed tracing tooling when more than one service exists — until then, the correlated logs ARE the trace.

## Client-side error tracking & real-user monitoring

9. **Required, not optional**: an error-tracking SDK captures unhandled exceptions and rejections in the browser with source maps, release tagging, and user-impact counts. The server being green while every client throws is the classic silent failure.
10. Real-user monitoring collects Core Web Vitals from the field — the lab budgets in `05-verification/a11y-perf-gates.md` are gates; field data is the truth they approximate.

## Alerting

11. Alert on **symptoms users feel** (error-budget burn, elevated 5xx, p95 over threshold, client error spikes), not on causes (CPU). Every alert is actionable and links a runbook (`incident-runbook.template.md`); an alert that's routinely ignored gets fixed or deleted.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: New or changed code paths emit structured logs with event name and context fields per the logging convention; no stray console debugging remains.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the lint config's console ban is injected via the preset and covers rule 1's mechanical half).
