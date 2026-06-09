# Web Security Headers

The browser is a hostile execution environment the application configures by declaration: a handful of response headers decide whether a stolen script runs, whether a page can be framed for clickjacking, whether a cookie survives a cross-site request, and whether traffic can be downgraded to plaintext. This doc owns those browser- and transport-layer controls — the design-time decisions that close OWASP's *Insecure Design* and *Security Misconfiguration* gaps before a public surface ships. It is the response-side complement to `03-design/threat-modeling.md` (which finds the threats) and the cross-cutting posture in `_spines/security-privacy.md`. The header *values* are a per-deployment configuration choice; the *requirement that they exist and are correct* is the rule.

## Transport security

1. **Public surfaces are HTTPS-only; plaintext is redirected, not served.** Every externally reachable endpoint terminates TLS; an HTTP request is answered with a redirect to its HTTPS equivalent and nothing sensitive (no cookies, no body content) is returned over the cleartext leg.
2. **Declare strict transport security so the browser refuses the downgrade.** A long-lived strict-transport directive (a `max-age` of at least one year) instructs the browser to use HTTPS for the host for that duration, defeating SSL-stripping man-in-the-middle attacks after first contact. Apply it to subdomains where they are all HTTPS-capable; treat preload-list submission as a one-way commitment made deliberately, never as a default, because it is slow to undo.
3. **Transport security is asserted, not assumed.** The strict-transport header is part of the header set verified at launch (rule 12), because a TLS-terminating proxy that forgets to set it leaves every first-of-session request downgradeable.

## Content Security Policy

4. **A public HTML surface ships a Content-Security-Policy, and it defaults to deny.** Set a restrictive default fetch directive (`default-src 'none'` or `'self'`) and then **explicitly allow** only the sources each resource type needs — script, style, image, font, connect, frame. A policy is a budget of trusted origins, not an afterthought; a missing policy means any injected markup executes with the page's full authority.
5. **Name script and style sources explicitly; do not reach for the broad escape hatches.** Avoid `unsafe-inline` and `unsafe-eval` for scripts — they reopen exactly the cross-site-scripting class the policy exists to close. Where inline scripts are unavoidable, gate them with a per-response nonce or a content hash rather than blanket-allowing inline execution.
6. **Roll the policy out report-only, then enforce.** Deploy the policy first in its report-only mode with a violation-reporting endpoint, observe real traffic to find the legitimate sources the policy would have blocked, fold them in, and only then switch to the enforcing header. Shipping an untested enforcing policy breaks the site; shipping no policy leaves it open — report-only is the bridge between the two.
7. **Keep the reporting channel alive after enforcement.** A violation report on an enforcing policy is an early signal of an injection attempt or a drifted third-party dependency; the report endpoint stays wired up, not removed once the policy "works."

## Framing and clickjacking

8. **State who may frame the page, and default to no one.** Control framing with the policy's frame-ancestors directive: `'none'` for surfaces that should never be embedded, an explicit allowlist of origins for those that must be. This is the clickjacking defense — it stops a malicious site from overlaying your authenticated UI inside an invisible frame.
9. **Carry the legacy frame header alongside, not instead.** Older agents that ignore frame-ancestors still honor the legacy anti-framing header (`DENY`/`SAMEORIGIN`); send both so the defense degrades gracefully, treating the modern policy directive as authoritative where the two are read together.

## Content-type and content-sniffing

10. **Disable MIME sniffing.** Send the no-sniff content-type-options directive so the browser honors the declared `Content-Type` instead of guessing it — guessing is how an uploaded "image" gets interpreted and executed as script. This pairs with serving user-supplied content under a correct, locked-down content type.

## Referrer and capability minimization

11. **Minimize what the page leaks and what it may do.** Set a referrer policy that strips path and query from cross-origin navigations (a privacy-preserving default that does not send full URLs — which may carry identifiers or tokens — to third parties), and set a permissions policy that **denies the powerful browser capabilities the page does not use** (camera, microphone, geolocation, payment, and similar), allowlisting only those a feature actually needs. Default-off for capabilities is the same least-privilege posture as the default-deny policy.

## Cookies and the CSRF model

12. **Session and auth cookies carry the full safety triple.** Every cookie that authenticates or carries session state is set `Secure` (sent only over HTTPS), `HttpOnly` (unreadable by page script, so a cross-site-scripting foothold cannot exfiltrate it), and with an explicit same-site attribute. Default same-site to the lax behavior; use the strict behavior for the most sensitive cookies (admin sessions, anything authorizing money movement) where the usability cost of cross-site top-level navigations not carrying the cookie is acceptable.
13. **Same-site is a strong default, but it is not the whole CSRF defense.** State-changing requests (anything that creates, mutates, or deletes) must be protected against cross-site request forgery. The same-site cookie attribute covers a large share of cases, but it is browser-dependent and does not cover every embedding or method; therefore any state-changing request **not** otherwise protected by same-site carries a CSRF token — a synchronizer token bound to the session, or a double-submit token — that the server verifies before acting. Safe, side-effect-free reads need no token; unsafe verbs always do.
14. **Cross-site-readable APIs do not rely on the cookie's ambient authority.** An endpoint designed to be called cross-origin authenticates with an explicit credential (a bearer token in a header) rather than a cookie the browser attaches automatically, sidestepping the forgery surface entirely; cross-origin sharing rules are then scoped to the specific origins that need them, never reflected-open to all.

## Where the values live and how they are checked

15. **The concrete header set and policy are a per-deployment decision recorded in the architecture map.** Which origins the policy trusts, which capabilities the permissions policy allows, and which cookies are strict versus lax depend on the deployment's third parties and embedding needs — these belong with the project's configuration record (`01-context/architecture-map.template.md`), not hard-coded as a universal value. The rule is that the decision is made and written down; the choice is what it resolves to.
16. **The header set is verified at review and at launch.** A change that adds a third-party script, an embeddable surface, a new cookie, or a new cross-origin caller is a change to this contract and is reviewed as one. The full set — strict-transport, an enforcing default-deny policy, frame-ancestors, no-sniff, referrer and permissions policies, and the cookie triple plus CSRF defense — is verified at launch via the injected launch-readiness checklist, under the security & privacy category that gates a surface's threat-model mitigations (`06-delivery/launch-readiness.md`); a surface does not go public with the header contract unverified.

## Standards basis

- **OWASP Secure Headers Project** (owasp.org/www-project-secure-headers) — the consensus catalogue and recommended values for the headers in rules 2, 4–11 (Strict-Transport-Security, Content-Security-Policy, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, Permissions-Policy) and the "which to set and to what" guidance behind the verified header set.
- **OWASP Cross-Site Request Forgery Prevention Cheat Sheet** (cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html) — basis for rules 12–14: the synchronizer-token and double-submit-cookie patterns, SameSite cookies as defense-in-depth (not a sole control), and the safe-vs-unsafe-verb distinction.
- **Content Security Policy Level 3** (W3C; MDN Web Docs, developer.mozilla.org/docs/Web/HTTP/CSP) — the policy model in rules 4–9: fetch directives, `default-src`, nonces and hashes, `frame-ancestors`, and `Content-Security-Policy-Report-Only` for the report-then-enforce rollout.
- **RFC 6797 — HTTP Strict Transport Security (HSTS)** (datatracker.ietf.org/doc/html/rfc6797) — the `max-age`/`includeSubDomains` directive and downgrade-resistance semantics behind rules 2–3.
- **RFC 6265 — HTTP State Management Mechanism**, and its in-progress revision `draft-ietf-httpbis-rfc6265bis` which standardizes the `SameSite` attribute (MDN Set-Cookie reference) — the `Secure`, `HttpOnly`, and `SameSite` (Lax/Strict/None) attribute semantics behind rules 12–14.
- **OWASP Top 10 — the Security Misconfiguration and Insecure Design risk families** (owasp.org/Top10) — the two risk categories this doc closes at design time: missing/weak browser controls are the canonical misconfiguration, and shipping a public surface without a header contract is the canonical insecure design. (The library's spine tracks the 2025 edition, where Security Misconfiguration is A02 — `_spines/security-privacy.md`; these were A05 and A04 respectively in the 2021 edition. The A0x letters move between editions; the control families this doc relies on persist, so it names the families rather than pinning the edition-specific numbers.)
- Ties into `_spines/security-privacy.md` (the cross-cutting security posture and PII baseline) and `03-design/threat-modeling.md` (the per-feature method that surfaces the spoofing/tampering/disclosure threats these headers mitigate).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every public web surface ships HTTPS-only with HSTS, a default-deny Content-Security-Policy (frame-ancestors set, no `unsafe-inline`/`unsafe-eval` scripts), X-Content-Type-Options nosniff, and a minimized Referrer-Policy/Permissions-Policy; session/auth cookies are Secure + HttpOnly + SameSite; and every state-changing request not covered by SameSite carries a verified CSRF token.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the concrete header values and CSP are a per-deployment choice recorded in the project's architecture map; the injected `docs/launch-readiness.md` checklist carries the verification at launch).
