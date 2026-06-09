# API Evolution

How an externally-consumed HTTP API changes shape over time without breaking the clients that depend on it. `03-design/api-contract-design.md` defines the *shape* of a contract; this doc defines how that contract is **versioned, evolved, and retired** once strangers consume it. Internal same-repo APIs are out of scope — the type system is their migration tool (`03-design/api-contract-design.md` rule 9). Everything here applies the moment a second party (a third-party app, a partner, the public) calls the surface.

## 1. What counts as a breaking change

The classification is SemVer applied to the wire, not the package version:

1. **Additive = non-breaking (MINOR).** New optional request fields, new response fields, new endpoints, new enum *outputs* a tolerant client ignores, new optional query params. A conformant client written against the old contract keeps working unchanged.
2. **Breaking (MAJOR).** Removing or renaming a field; tightening a type or validation; changing a default; changing the meaning of an existing field or status code; adding a *required* request field; removing an enum value a client may send; changing auth or rate-limit semantics; changing pagination shape.
3. **The robustness asymmetry holds both ways but is not symmetric.** Be conservative in what you send (don't add required fields), liberal in what you accept — and *require clients* to tolerate unknown response fields (documented as a forward-compatibility contract) so additive output stays MINOR. A client that rejects unknown fields makes every addition breaking; that constraint is on them, stated in the contract, not a reason to freeze the schema.

## 2. Version negotiation: pick one scheme, declare it

A versioned API exposes a major version on every externally-consumed surface from day one. Choose **one** negotiation scheme per API and document it; do not mix.

4. **URI-path versioning is the default** (`/v1/...`, `/v2/...`). It is explicit, cacheable per RFC 9110 caching semantics, trivially observable in logs and gateways, and testable from a browser. Only the **major** appears in the path — minor/additive changes never mint a new path (rule 1).
5. **Media-type / header negotiation** (`Accept: application/vnd.example.v2+json`, or a header `Accept-Version`) is permitted when one resource needs multiple concurrent representations and URI churn is unacceptable. It is RFC 9110 §12 content-negotiation-correct but harder to test, cache, and debug — choose it deliberately, not by default. The chosen scheme is part of the contract (`03-design/api-contract-design.md`).
6. **Never version with an undeclared default.** A request that omits the version MUST NOT silently float to "latest" — pin it to a stated version (typically the oldest supported, or reject with `400`), because floating-latest turns every MAJOR release into a silent break for lazy clients.
7. **Minor/patch is not in the URL or header.** Within a major, only additive change ships (rule 1). The full semantic version is advertised out-of-band (changelog, an info endpoint, a response header), never used for routing.

## 3. Running versions in parallel: expand → migrate → contract

8. A MAJOR change ships the new version **alongside** the old, not in place of it (parallel change). Sequence: **expand** (publish `vN+1` while `vN` keeps serving) → **migrate** (consumers move on their own schedule, measured — `07-operations/observability.md` makes residual `vN` traffic answerable) → **contract** (retire `vN` per §4 once silence is proven). This is the contract-phase pattern of `03-design/api-contract-design.md` rule 8 applied across an externally-consumed boundary.
9. **State the support window up front.** Publish how many major versions run concurrently and for how long (the concrete numbers are a stack/product choice, not a global rule). A version with no stated end is debt wearing a sign (`08-maintenance/deprecation-process.md`).
10. **Errors are versioned surface too.** Every version emits errors as RFC 9457 Problem Details (`application/problem+json`); the `type` URI is stable, machine-readable API (`03-design/api-contract-design.md` rule 6). Changing a `type`'s meaning is breaking; adding a new `type` is additive.

## 4. The retirement contract: Deprecation → Sunset → 410

Withdrawal is a forward, announced process — never a silent break. A retired endpoint cannot be "rolled back" for clients already bound to it (`06-delivery/rollback.md` "Retiring a public API"). The signalling sequence is machine-readable and ordered:

11. **Deprecate (RFC 9745).** Once a version/resource is no longer preferred, every response carries a `Deprecation` HTTP header — a Structured Field Date (`@<unix-timestamp>`, seconds since epoch) at or before *now*. Pair it with a `Link` header `rel="deprecation"` pointing at the migration guide. Per RFC 9745 the header changes **no** behavior: deprecated endpoints keep working until sunset.
12. **Announce a removal date (RFC 8594).** Alongside `Deprecation`, emit a `Sunset` HTTP header (an IMF-fixdate) naming the instant the resource stops responding. `Sunset` is in the future; `Deprecation` is in the past or now. The date respects how fast real consumers can move (rule 9) and the changelog announces it in human-readable form (`08-maintenance/deprecation-process.md` step 2).
13. **Prove silence before removing.** Do not contract on a schedule alone — confirm zero (or accepted-residual) `vN` traffic over a full usage cycle via telemetry (`07-operations/observability.md`) before the sunset fires. Deleting a surface strangers still call is ask-first, always (`08-maintenance/deprecation-process.md`).
14. **After sunset, respond `410 Gone`** (RFC 9110 §15.5.11) — the defined status for a resource intentionally and permanently removed — not `404` (which means "absent/hidden" and invites retries). Keep the `410` (with a Problem Details body pointing at the replacement) live for a stated grace period so stragglers get a diagnosable signal, not a silent connection refusal.

## 5. Discipline

15. **Version from day one for external surfaces; never retrofit.** Adding `/v1` after clients depend on the unversioned path is itself a breaking change.
16. **One change, one classification.** Every external-API PR states whether it is additive (MINOR) or breaking (MAJOR) and, if breaking, which §3/§4 phase it belongs to — mirroring the rollback-path declaration the PR template already requires (`06-delivery/rollback.md`).

## Standards basis

- **RFC 9110 — HTTP Semantics** (Internet Standard, STD 97, https://www.rfc-editor.org/rfc/rfc9110): caching of path-versioned resources, content negotiation (§12) for media-type versioning, and `410 Gone` (§15.5.11) as the defined permanent-removal status. Grounds rules 4–5 and 14.
- **RFC 9457 — Problem Details for HTTP APIs** (`application/problem+json`; obsoletes RFC 7807): versioned, machine-readable error bodies whose `type` URI is stable API surface. Grounds rule 10 and the `410` body in rule 14.
- **RFC 9745 — The Deprecation HTTP Response Header Field** (Proposed Standard, March 2025; https://www.rfc-editor.org/rfc/rfc9745, IANA-registered permanent field): the `Deprecation` Structured-Field-Date header (`@unix-timestamp`) plus `Link rel="deprecation"`; deprecation signals, never alters, behavior. Grounds rule 11.
- **RFC 8594 — The Sunset HTTP Header Field** (Informational; https://www.rfc-editor.org/rfc/rfc8594): the `Sunset` IMF-fixdate header and `sunset` link relation advertising when a URI stops responding. Grounds rule 12, and the ordering Deprecation-now → Sunset-future.
- **SemVer 2.0.0** (https://semver.org): additive = MINOR (backward-compatible), removal/semantic change = MAJOR (breaking). Grounds the breaking-change classification (rules 1–2) and the major-in-URL rule (rules 4, 7).
- **Robustness Principle (RFC 9413 / Postel)** (https://www.rfc-editor.org/rfc/rfc9413): conservative in what you send, liberal in what you accept — the tolerant-reader contract that keeps additive output non-breaking (rule 3). RFC 9413 tempers it: tolerance is a documented contract, not unbounded leniency.
- **Parallel Change / expand–contract** (Fowler, https://martinfowler.com/bliki/ParallelChange.html): run new and old in parallel, migrate, then retire — the safe path for a MAJOR across a live external boundary (§3, §4).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this PR changes an externally-consumed API, it states whether the change is additive (MINOR) or breaking (MAJOR), and any breaking change ships a new major version in parallel and signals retirement of the old via Deprecation → Sunset → 410 rather than removing it in place.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only.
