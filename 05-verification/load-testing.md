# Load & Capacity Testing

The Lighthouse gate (`05-verification/a11y-perf-gates.md`) measures one session in a lab; it says nothing about behavior under hundreds of concurrent users. This doc covers performance **under load** — where the system saturates, whether it holds its latency SLO at peak, and how much headroom exists before it falls over. It is a **pre-launch and pre-traffic-event** activity, not a per-PR gate.

## What and when

1. **Test the revenue-critical paths under realistic concurrency** — the same journeys the E2E crown guards (`04-build/testing-strategy.md`), driven at expected peak load, not a single synthetic hammer on one endpoint. The script models real user behavior (think-time, mixed actions), because uniform max-rate traffic finds different limits than real load.
2. **Derive the pass/fail bar from the SLO, not a vanity number.** The test passes if the **latency SLO holds (p95/p99) and the error rate stays in budget** at the target load with headroom (e.g. 2× expected peak); it fails if either breaches. The SLO (`07-operations/slo-error-budgets.md`) is the contract the load test verifies.
3. **Run it at the moments load changes, not continuously:** before first launch, before a known traffic event (campaign, launch, seasonal peak), and after an architecture or capacity-relevant change. Between those, field RUM + SLO burn alerts (`_spines/performance.md`) are the ongoing signal.

## The kinds of test

4. **Use the right shape for the question:** **load** (steady expected peak — does the SLO hold?), **stress** (ramp past peak — where's the breaking point and does it fail gracefully?), **spike** (sudden surge — does it absorb or shed load cleanly?), and **soak** (sustained load for hours — memory/connection leaks, resource creep). A launch needs at least a load + a soak; stress/spike where a surge is plausible.
5. **Capacity planning falls out of the stress test.** Find the **knee** (where latency degrades non-linearly), know your headroom above expected peak, and set autoscaling bounds / connection-pool / rate limits (`03-design/rate-limiting-abuse.md`) from measured numbers — not guesses. "We can handle launch" is a measurement, not a hope.
6. **Test in a production-like environment, and degrade safely if testing prod.** Load against a prod-shaped environment with prod-shaped data; never blind-hammer production. Coordinate with rate limits and have a kill-switch — a load test that takes down the real service is an outage you scheduled.

## Standards basis

- **Google SRE — Addressing Cascading Failures, Handling Overload, and "Non-Abstract Large System Design"** (*Site Reliability Engineering*): load shedding, graceful degradation under overload, and capacity from measured headroom — the basis for rules 2, 4–6 (find the knee, fail gracefully, plan from data). Pairs with `_spines/reliability.md`.
- **The four load-test types — load / stress / spike / soak** (the standard performance-testing taxonomy, e.g. k6 and Gatling test-type guides): rule 4.
- **Little's Law / queueing theory** (L = λW) — the formal basis for capacity reasoning (concurrency = arrival rate × latency); grounds rule 5's knee/headroom analysis.
- **Core Web Vitals field data** (`_spines/performance.md`, `07-operations/observability.md`) — the lab/load tests approximate; field RUM at p75 is the ongoing truth between load tests.

## Enforcement
- Mechanism: none-possible
- Config: n/a — the load-test harness (k6 or equivalent) and target environment are per-project; the latency SLO it checks lives in `docs/slos.md`.
- Fallback if unenforceable: If this change alters a hot path, capacity, or precedes launch or a known traffic event, run a load test (plus a soak before launch) and confirm the latency SLO and error budget hold at target load with headroom; record the measured knee and headroom.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the load-test tool and prod-like environment are per-project choices; the SLO it validates is injected as `docs/slos.md`).
