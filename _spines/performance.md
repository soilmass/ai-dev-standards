# Performance & Efficiency Spine

Performance is not a layer — it's a budget every layer spends or saves. This spine doesn't duplicate the layer rules; it shows **where performance bites in each layer**, owns the cross-cutting decisions no single layer can (caching, latency budgets, the lab-vs-field contract), and ties the frontend gate (`05-verification/a11y-perf-gates.md`) to the field truth (`07-operations/observability.md`).

## Where it bites, layer by layer

| Layer | Performance obligation | Lives in |
|---|---|---|
| 02 Product | Performance is in the acceptance criteria — a target load/interaction budget, not "fast enough" | `02-product/acceptance-criteria.md` |
| 03 Design | API/query shape avoids N+1 and over-fetching; the **caching strategy** is decided here (below); expensive paths are rate-/cost-budgeted | `03-design/data-modeling.md`, `03-design/api-contract-design.md`, `03-design/rate-limiting-abuse.md` |
| 04 Build | Ship less: code-split, defer/lazy non-critical work, keep the dependency (and bundle) weight down | `04-build/dependency-policy.md`, `04-build/coding-standards.md` |
| 05 Verification | Lab gate — Lighthouse Core Web Vitals budgets (LCP/CLS/TBT) block the PR | `05-verification/a11y-perf-gates.md` |
| 06 Delivery | High-risk changes roll out behind a flag; release is watched against the latency SLO for one budget-relevant interval | `06-delivery/release-process.md`, `06-delivery/deployment-strategy.md` |
| 07 Operations | Field RUM (Core Web Vitals at p75) is the truth; latency SLOs + burn alerts watch it; third-party latency is observed | `07-operations/observability.md`, `07-operations/slo-error-budgets.md` |
| 08 Maintenance | Cache-invalidation and slow-path debt is logged; periodic budget review catches drift | `08-maintenance/tech-debt-policy.md` |

## Cross-cutting rules owned here

1. **The lab gate approximates; the field is the truth.** The Lighthouse budgets in `05-verification/a11y-perf-gates.md` are a fast pre-merge proxy; real-user **Core Web Vitals at p75** (`07-operations/observability.md` rule 10) are what users feel. A green lab run with a failing field p75 means lab conditions don't match real devices/networks — investigate before tightening or relaxing a gate (calibration CAL-C02/C09). Set the SLO from measured reality, not the lab number.
2. **Caching is a deliberate, cross-layer decision, not an accident.** For each cacheable response decide **what** is cached, **where** (browser via `Cache-Control`/`ETag`, CDN/edge, server/data layer), for **how long**, and **how it is invalidated** — record it in the architecture map. The hardest half is invalidation: prefer keying on content/version (a changed key is a free invalidation) over time-based guesses, and never cache per-user/PII data in a shared tier (`_spines/security-privacy.md`). A cache with no stated invalidation path is a correctness bug waiting to ship stale data.
3. **Budget the work, at the right layer.** Frontend weight is gated by the CWV budgets; backend cost is budgeted as a **per-route latency target** (an SLI in `docs/slos.md`, p95/p99 — not one global number) and by guarding query complexity and N+1 reads at design (`03-design/data-modeling.md`). Bundle-size and query-complexity budgets are per-project numbers set from the project's own baseline (like the SLO/RPO bounds), then held against regression — not fixed library constants.
4. **Spend on the critical path only.** Do the minimum work to first interaction: defer, lazy-load, stream, or move off the request path (background job, edge cache) anything not needed to render or respond. Compression (Brotli/gzip) and a CDN for static assets are table stakes, not optimizations.
5. **Degrade on slowness, don't hang.** A slow dependency is a performance failure: every outbound call has a short timeout and a fallback (the resilience patterns in `04-build/third-party-integrations.md` and `_spines/reliability.md`) so one slow service can't blow the whole route's budget. Timeout < the cache TTL, so stale-but-fast beats fresh-but-down.
6. **Measure before optimizing, and keep the receipt.** Optimize against a profile/RUM signal, not a hunch; a perf change states the before/after number it moved. Premature micro-optimization that complicates code without a measured win is debt, not a win.

## Standards basis

- **Core Web Vitals** (web.dev/articles/vitals) — **LCP** (loading), **INP** (interactivity, which replaced FID in 2024), **CLS** (visual stability), assessed at the **p75** field percentile. The basis for rules 1 and 3 and the gate↔field contract.
- **RAIL performance model** (Response/Animation/Idle/Load; web.dev) — user-centric budget thinking (≈100 ms response, ≈50 ms frames, ≈5 s load on mid-tier mobile); grounds the "budget the work on the critical path" framing of rules 3–4.
- **Performance budgets** (Alex Russell / web.dev "performance-budgets-101") — set a budget, gate against it, treat a regression as a build break: rule 3.
- **HTTP caching — RFC 9111** (`Cache-Control`, `ETag`/`If-None-Match`, `stale-while-revalidate`) and CDN/edge caching: the standards behind the caching rule 2; cache-key/versioned invalidation is the long-standing "two hard things" discipline.
- **Latency percentiles / tail latency** (Dean & Barroso, "The Tail at Scale") — why p95/p99 per-route, not the mean, is the right SLI (rule 3); pairs with **Google SRE** SLO/error-budget practice (`07-operations/slo-error-budgets.md`).
- Builds on `05-verification/a11y-perf-gates.md` (the lab gate — owned there), `07-operations/observability.md` (field RUM — owned there), `03-design/rate-limiting-abuse.md` (cost limits), and `_spines/reliability.md` (timeouts/degradation). This spine adds the caching, latency-budget, and lab-vs-field connective tissue across them.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/lighthouserc.json + stacks/nextjs-default/ci/pr.yml (Lighthouse Core Web Vitals gate) — the lab subset; field SLOs are per-project and live in `docs/slos.md`, and each layer row above names its own gate.
- Fallback if unenforceable: n/a — the lab budgets are CI-gated and the field/latency pieces ride the SLO discipline in `docs/slos.md`; caching/critical-path judgment is reviewable against the architecture map and the perf acceptance criterion.

## Bootstrap
- What new-project.sh injects for this standard: nothing additional — the `lighthouserc.json` budgets, the CI Lighthouse job, the `docs/slos.md` template (latency SLI), and the architecture-map template it already injects are this spine's enforcement surface.
