# Cost & FinOps Spine

Cost is not a layer — it's a non-functional requirement every layer can quietly blow, and for a solo operator an unbounded bill or a denial-of-wallet attack is an availability incident. This spine doesn't duplicate the layer rules; it shows **where cost bites in each layer**, owns the cross-cutting framing (cost as a budgeted, observed metric), and points at the limits and signals that keep spend bounded.

## Where it bites, layer by layer

| Layer | Cost obligation | Lives in |
|---|---|---|
| 02 Product | A feature that costs per-use (paid API, LLM, large compute) states its expected unit economics in the spec — "what does one use cost us?" | `02-product/spec.template.md`, `02-product/acceptance-criteria.md` |
| 03 Design | Expensive/metered endpoints carry a **cost-based limit** (not just a request count); architecture avoids per-request fan-out to paid services | `03-design/rate-limiting-abuse.md` |
| 04 Build | Dependencies are justified against their weight (install/transitive/runtime cost); no needless paid-service calls | `04-build/dependency-policy.md` |
| 06 Delivery | Hosting model is chosen with its cost shape in mind (serverless per-invocation vs. warm container) | `00-governance/pinned-decisions.md`, `06-delivery/deployment-strategy.md` |
| 07 Operations | Cost is **observed**: metered third-party call volume and spend are emitted and alerted, like any other golden signal | `07-operations/observability.md` |
| 08 Maintenance | Unused paid deps/services are pruned; accepted-cost trade-offs are re-confirmed on the quarterly sweep | `04-build/dependency-policy.md` (quarterly prune), `08-maintenance/tech-debt-policy.md` |

## Cross-cutting rules owned here

1. **An uncapped expensive endpoint is a denial-of-wallet vulnerability.** Any path that triggers a paid third-party/LLM call, a large export, an email/SMS send, or heavy compute must be **cost-budgeted at the boundary** — by a per-user/per-key cost or token bucket, a concurrency cap, or a hard quota (`03-design/rate-limiting-abuse.md` rule 3). This is the same OWASP "unrestricted resource consumption" risk as a DoS, pointed at the bill instead of the CPU.
2. **Cost is a metric you emit from day one, not a surprise on the invoice.** Metered third-party/LLM call volume (and, where the provider exposes it, spend) is an observable signal with a threshold alert (`07-operations/observability.md` rule 11) — a vendor silently 10×-ing your usage or an abuse spike should page on *cost burn*, not be discovered at month-end. You can't bound what you don't measure.
3. **Every dependency and integration has a cost, and it's part of the decision.** Adding a library carries install/transitive/runtime weight (`04-build/dependency-policy.md`); adopting a paid SaaS carries a recurring bill and a per-call rate. The ADR that adopts a runtime integration (`04-build/third-party-integrations.md`) names its cost model and a kill-switch, so a cost spike has an off-ramp.
4. **Pick the cost shape deliberately, then right-size.** The hosting decision (`00-governance/pinned-decisions.md`'s three-box model) is partly a cost-shape decision — serverless trades a low floor for per-invocation cost that a hot path can blow, while a warm container trades a fixed floor for cheap throughput. Choose for the workload, and don't over-provision "just in case."
5. **Prune what you don't use.** Unimported dependencies, idle paid services, and over-broad provisioned capacity are recurring cost with no value; the quarterly dependency prune and debt sweep (`08-maintenance/*`) re-confirm that every recurring cost still earns its place.

## Standards basis

- **FinOps Foundation — FinOps Framework** (finops.org) — the operating model of *inform → optimize → operate* and the principle that engineers take ownership of the cost of what they build; grounds rules 2–5 (cost as an owned, observed, continuously-reviewed metric) scaled to a solo operator.
- **OWASP API Security Top 10 — API4:2023 Unrestricted Resource Consumption** (owasp.org/API-Security) — explicitly names the financial dimension ("can lead to … increased operational costs"), i.e. **denial-of-wallet**; the basis for rule 1. Shares the limit mechanics with `03-design/rate-limiting-abuse.md`.
- **Cloud cost / right-sizing & the serverless cost model** (AWS/GCP Well-Architected Cost-Optimization pillar) — match capacity to demand, understand per-invocation vs. fixed-floor trade-offs; grounds rule 4.
- Builds on `03-design/rate-limiting-abuse.md` (cost limits — owned there), `04-build/dependency-policy.md` (dependency weight), `04-build/third-party-integrations.md` (integration cost + kill-switch), and `07-operations/observability.md` (cost as a signal). This spine names cost as a first-class, budgeted, observed concern across them rather than an afterthought.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Expensive or metered operations (paid third-party/LLM calls, large exports, fan-out, email/SMS) carry a cost budget or limit at the boundary and emit an observable cost signal; new dependencies and paid integrations are justified against their cost; no endpoint is an uncapped denial-of-wallet surface.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (cost budgets, the chosen hosting cost-shape, and the cost-metric vendor are per-project choices; the rate-limit, dependency-policy, and observability surfaces this spine points at are injected by their own standards).
