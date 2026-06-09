# Third-Party Integration Lifecycle

`dependency-policy.md` and `supply-chain.md` govern the code you *build with*; this doc governs the services you *call at runtime* — payment processors, auth providers, email/SMS, CDNs, analytics, LLM APIs. Every one is a piece of your availability, latency, security, and cost surface that you do not control. Treat each as a deliberate, reversible, observable coupling, not an SDK you drop in and forget.

## Adopt with eyes open

1. **A new third-party service is an architectural decision recorded as an ADR** (`01-context/adr.template.md`) and added to the architecture map (`01-context/architecture-map.template.md`) as an external dependency. The ADR names what it does, the data that crosses to it, its failure blast radius, and the exit path — switching cost is part of the decision, not a future surprise.
2. **The data crossing the boundary is classified before the integration ships.** If PII or payment data flows to the vendor, it is a processor under `03-design/data-privacy.md` (named in the retention/DSR map, covered by a signed data-processing agreement — a DPA, or a BAA where a regime like HIPAA requires one) and an asset in the feature's threat model. "It's just an API call" is how PII silently leaves the building.
3. **Prefer the integration that minimizes what you hold.** Tokenized/redirect flows (e.g. hosted payment fields) that keep you out of scope beat ones that route sensitive data through your servers — every byte you don't touch is breach blast radius and compliance scope you don't carry (`03-design/data-privacy.md` rule 6).

## Build for the failure, because it will fail

4. **Every outbound call has a timeout, and the timeout is short.** A dependency without a timeout is a dependency that can hang your whole request when *it* slows down — the classic cascading failure. No call inherits the default (often infinite) socket timeout.
5. **Wrap unstable or critical dependencies in a circuit breaker with a defined fallback** (Nygard's stability patterns). When the downstream is failing, stop hammering it, fail fast, and degrade: serve cached/stale data, queue the work, or show an honest "temporarily unavailable" — never let one vendor's outage become a full outage if the feature can survive degraded.
6. **Decide the degradation per integration and write it down.** Some failures must block (no payment authorization → no order); most should degrade (analytics down → drop the event, never the page; email down → queue and retry). The blocking-vs-degrading choice is a product decision recorded in the ADR, not an accident of where the error bubbled to.
7. **Retries are bounded, backed off, jittered, and idempotent.** Retry only idempotent operations (or use an idempotency key so a retried charge doesn't double-bill), cap the attempts, use exponential backoff with jitter, and never retry a 4xx that will fail identically. Unbounded retries turn a vendor blip into a self-inflicted DDoS on both ends.

## Secure the seam

8. **Credentials follow the secrets standard, scoped to least privilege.** Integration keys live in the validated env schema (`04-build/secrets-config.md`), never in code; use the narrowest scope/role the vendor offers, separate keys per environment, and rotate on the standard cadence (and immediately on exposure).
9. **Verify inbound webhooks; trust nothing unauthenticated.** A webhook endpoint is an unauthenticated public route until proven otherwise — verify the signature (HMAC/shared secret per the vendor's scheme), check timestamp freshness to stop replays, make handlers idempotent (vendors redeliver), and validate the payload at the boundary like any external input.
10. **Guard against SSRF and untrusted responses.** Treat data coming back from a third party as untrusted input — validate it against the expected schema, and for any feature that fetches a user- or vendor-supplied URL, constrain the destination (allowlist hosts, block internal/metadata IP ranges) so the integration can't be turned into a request-forgery pivot (OWASP API/SSRF guidance).

## Operate and retire

11. **Integration health is observable and its cost is watched.** Emit per-dependency latency, error rate, and (where it's metered/paid) call volume; alert on a dependency's error-budget burn the same way as your own (`07-operations/observability.md` rule 11). A vendor degrading silently while you eat the latency or the bill is the failure mode this catches; surprise overage is denial-of-wallet from your own side.
12. **Removal is the deprecation process, not a deleted file.** Retiring or swapping a provider runs through `08-maintenance/deprecation-process.md` — migrate off, verify nothing still calls it, then remove the keys, the SDK, and the ADR's "active" status. A dangling integration is dead code with live credentials attached.

## Standards basis

- **Michael Nygard, *Release It!* — Stability & Capacity patterns** (Timeout, Circuit Breaker, Bulkhead, Fail Fast, Steady State): the canonical source for rules 4–6; an integration without timeouts and a breaker is the textbook cascading-failure setup.
- **Martin Fowler — CircuitBreaker** (martinfowler.com/bliki/CircuitBreaker.html): the pattern write-up grounding rule 5's open/half-open/closed degradation.
- **Exponential backoff with jitter** (AWS Architecture Blog, "Exponential Backoff And Jitter") and **idempotency keys** (the Stripe/Idempotency-Key model): rule 7 — bounded, jittered, idempotent retries that don't amplify an outage or double-charge.
- **OWASP API Security Top 10 — API10:2023 Unsafe Consumption of APIs** and **SSRF guidance** (owasp.org): the basis for rules 9–10 — third-party responses and webhooks are untrusted input, and URL-fetching features are SSRF pivots.
- **OWASP Webhook security / signature verification**: HMAC signature + timestamp + idempotency as the inbound-webhook trust floor (rule 9).
- **NIST SP 800-161 / ISO/IEC 27001 A.5.19–A.5.22 (supplier relationships)**: third-party/vendor risk as a managed lifecycle — corroborates the adopt-with-ADR and retire-deliberately framing (rules 1, 12), at the vendor-governance level.
- Distinct from `04-build/supply-chain.md` (build-time artifact provenance) and `04-build/dependency-policy.md` (libraries); shares `04-build/secrets-config.md` (keys), `03-design/data-privacy.md` (processors), `03-design/threat-modeling.md` (boundary), and `08-maintenance/deprecation-process.md` (retirement).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Each third-party runtime integration is recorded as an ADR and in the architecture map with its data classification; every outbound call has a short timeout and a written blocking-vs-degrading fallback; retries are bounded/backed-off/idempotent; inbound webhooks are signature-verified and idempotent; keys are least-privilege env secrets; and removal runs through the deprecation process.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (each integration's SDK, keys, and resilience wiring are per-project choices; the injected env schema, ADR template, and architecture-map template carry the slots this doc fills).
