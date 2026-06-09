# Rate Limiting & Abuse Prevention

An endpoint with no rate limit is a denial-of-wallet and credential-stuffing surface waiting to be found. This doc governs how the API's request budget is **designed at the boundary** — who gets how much, what happens at the ceiling, and which surfaces need abuse controls beyond a simple counter. It is a design-time decision (it shapes the contract in `api-contract-design.md`), not an ops afterthought.

## What gets a limit, and keyed by what

1. **Every publicly reachable mutating or expensive endpoint declares a rate-limit strategy** before it ships — auth, search, file upload, anything that writes, sends mail/SMS, or fans out to a paid downstream. "Behind login" is not a limit; an authenticated user can still hammer or be compromised.
2. **Key the limit to the right identity, in order of trust:** authenticated user/account ID first; API-key/client ID for service callers; source IP only as the fallback for unauthenticated traffic (it is shared behind NAT/CGNAT and spoofable on some paths, so it is the coarsest, last-resort key). Sensitive flows often need **two** limits — a tight per-account limit *and* a looser per-IP limit — so one compromised account can't exhaust a shared pool and one IP can't farm many accounts.
3. **Limit the scarce resource, not just the request count.** A request that triggers an email, a large export, an LLM call, or a third-party charge costs far more than a cache read; budget those by cost (concurrency caps, token/credit buckets, or per-operation quotas) rather than a single global requests-per-minute number.

## The algorithm and its budget

4. **Default to a token bucket** (steady refill rate + burst capacity): it absorbs legitimate bursts while bounding sustained throughput, and its two parameters (rate, burst) map directly onto "N per minute, up to M at once." Sliding-window counters are the acceptable alternative; fixed calendar-window counters are not — they allow a 2× burst across the window boundary.
5. **The limiter's state lives in shared storage, not process memory.** On serverless or multi-instance hosting, an in-memory counter resets every cold start and is per-instance, so the real limit becomes `configured × instance-count` — i.e. no limit. Use the platform's atomic shared store (the stack ADR records which).
6. **Fail safe, and decide the direction deliberately.** If the limiter backend is unreachable, an auth or payment endpoint should **fail closed** (reject) while a read endpoint may **fail open** (allow) to preserve availability — the choice is per-endpoint and recorded, never an accident of where the try/catch landed.

## The 429 contract

7. **Over-limit returns `429 Too Many Requests` with a `Retry-After` header** (RFC 6585) so a well-behaved client backs off instead of tightening the loop. Expose the budget with the standard `RateLimit-Limit` / `RateLimit-Remaining` / `RateLimit-Reset` response fields (IETF `RateLimit header fields` draft) on normal responses too, so clients self-throttle before they hit the wall.
8. **429 is part of the API contract** (`api-contract-design.md`): it is documented, returns the standard error envelope, and is covered by a test. A limit nobody can discover until they trip it is a usability bug; a limit with no test rots.
9. **Never leak the limiter as an oracle.** Rate-limit responses must not reveal whether an account exists or a password was close — auth throttling returns the same generic 429/401 shape regardless, or the limiter itself becomes an enumeration tool.

## Abuse beyond rate limiting

10. **Authentication endpoints get abuse controls, not just a counter.** Login, password-reset, MFA, and signup are credential-stuffing and enumeration targets (OWASP Automated Threats OAT-008/OAT-007): combine per-account + per-IP limits with progressive backoff or lockout, a bot/proof-of-work or CAPTCHA challenge on anomalous bursts, and breached-password rejection. These belong in the feature's threat model (`03-design/threat-modeling.md`).
11. **Bound the request itself, upstream of the handler.** Cap body size, JSON depth/array length, file size and upload count, and query pagination limits at the boundary — unbounded inputs are a resource-exhaustion vector (OWASP API4:2023) that a per-minute counter never catches because one request does the damage.
12. **Distinguish throttling from blocking.** Rate limiting slows a legitimate-but-noisy client; blocking (deny-list, account suspension, WAF rule) stops a confirmed-malicious one. Have both, keep them separate, and make blocks expiring-by-default with a recorded reason — a permanent silent block is the moderation equivalent of unlogged debt.

## Standards basis

- **RFC 6585 — Additional HTTP Status Codes** (httpwg.org/specs/rfc6585.html): defines **429 Too Many Requests** and its use with the **`Retry-After`** header — the basis for rules 7–8.
- **RateLimit header fields for HTTP** (IETF httpapi WG Internet-Draft, `RateLimit-Limit`/`RateLimit-Remaining`/`RateLimit-Reset`): the emerging standard for advertising a request budget in responses so clients self-throttle — rule 7's discoverability half.
- **OWASP API Security Top 10 — API4:2023 Unrestricted Resource Consumption** (owasp.org/API-Security): the canonical framing that missing rate/size/cost limits is a top API risk (denial-of-service and denial-of-wallet); grounds rules 1, 3, and 11.
- **OWASP Automated Threats to Web Applications (OAT)** (owasp.org/www-project-automated-threats-to-web-applications): catalogues credential stuffing (OAT-008), credential cracking, account creation, and scraping as automated abuse classes that need controls beyond a generic counter — rule 10.
- **OWASP ASVS — V2 Authentication & V11 Business Logic** (rate-limiting and anti-automation requirements): the verification-level requirements for throttling sensitive functions and bounding business-logic abuse.
- **Token bucket / leaky bucket** (the classic traffic-shaping algorithms): rule 4's default; steady refill with bounded burst is the well-understood shape that fixed windows lack.
- Ties into `03-design/api-contract-design.md` (429 is a documented contract response), `03-design/threat-modeling.md` (abuse surfaces are modeled per feature), and `07-operations/observability.md` (sustained 429 rate and limiter-backend health are alertable symptoms).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every publicly reachable mutating or expensive endpoint declares a rate-limit strategy keyed to the right identity (account before IP), returns 429 with Retry-After on over-limit, and bounds request size/cost at the boundary; auth endpoints additionally carry anti-automation controls named in the feature's threat model.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the rate-limit store and middleware are a per-stack choice recorded as an ADR; the threat-model template it injects carries the abuse surfaces this doc builds on).
