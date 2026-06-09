# API Contract Design

Contracts before handlers: the shape of every API is declared as a schema first, and both sides consume that declaration. This is what keeps the front and back ends from drifting — especially when different agent runs build each side.

## Contract-first principle

1. Every endpoint/action declares its input schema and output schema **before** implementation, in the validation library the stack pins. The schema is the contract; the handler implements it.
2. Types are **inferred from the schemas** and shared front↔back from one module — never hand-duplicated interface declarations on each side. One declaration, both directions.
3. Handlers parse input through the schema at the boundary (reject early, typed thereafter) and — in development and tests — validate output against the response schema too.

### How sharing works in practice

- One contract module per resource (a `contracts/` or `schemas/` area): each file exports the schema written in the stack's validation library, plus the types **inferred** from that schema.
- Server code imports the schema itself — it needs the runtime parser to validate input at the boundary.
- Client code imports **only the inferred types** — never the validator runtime, never a re-declared interface.
- A contract change is therefore one file's diff: the schema and its inferred types move together, reviewed once, and every consumer recompiles against it (`03-design/architecture-standards.md` rule 6).

## The error envelope

4. All errors cross the wire in one standardized shape:

   ```jsonc
   // shape: error.code machine-readable snake_case; error.message human-readable,
   // no internals leaked; error.details optional (e.g. per-field validation issues)
   {
     "error": {
       "code": "validation_failed",
       "message": "The request could not be processed.",
       "details": [{ "path": "email", "issue": "must be a valid email address" }]
     }
   }
   ```

5. `code` values are stable API surface (clients branch on them); changing one is a breaking change. `message` is for humans and may change freely. Stack traces, SQL, and internal identifiers never leave the server (`_spines/security-privacy.md`).
6. Transport status (HTTP) carries the class of failure; `error.code` carries the specifics. Both are asserted in tests. Map status to semantics per RFC 9110: 400 malformed, 401 unauthenticated, 403 authenticated-but-forbidden, 404 absent/hidden, 409 conflict, 422 well-formed-but-invalid, 429 rate-limited, 5xx server fault. The envelope above is this library's house shape; externally consumed APIs SHOULD instead emit RFC 9457 Problem Details (`application/problem+json` with `type`/`title`/`status`/`detail`/`instance`) so generic clients interoperate — the local `error.code` maps to a Problem `type` URI.

### Method & idempotency semantics

The contract also declares each endpoint's HTTP method honestly (RFC 9110 §9):

- GET/HEAD are safe (no observable state change) and cacheable; never mutate behind a GET.
- PUT and DELETE are idempotent — repeating the call lands the same state. POST is neither safe nor idempotent.
- Non-idempotent mutations that may be retried (payments, resource creation) accept an idempotency key so a replayed request is de-duplicated server-side, not re-executed.

## Versioning & evolution

7. **Additive changes are free** (new optional fields, new endpoints). Anything else — removing/renaming fields, tightening types, changing semantics — is breaking.
8. Breaking changes follow expand → migrate → contract: ship the new shape alongside the old, move consumers, then retire the old shape on a stated schedule (`08-maintenance/deprecation-process.md`).
9. Internal app APIs (same repo, one consumer) need no version namespace — the type system is the migration tool. Externally consumed APIs get explicit versioning from day one.

## List endpoints: pagination, filtering, sorting

A collection endpoint is a contract too, and it is the one most likely to fall over at scale. The shape of how a list is paged, filtered, and sorted is declared in the same schema as everything else — and the wrong default here is a correctness bug (skipped or duplicated rows) before it is a performance one.

10. **Cursor/keyset pagination is the default; offset/limit is the exception for small bounded sets.** An offset walk re-counts and discards the skipped rows on every page (cost grows with depth) and skews when the set mutates mid-pagination — a row inserted or deleted ahead of the cursor shifts every later page, so a client paging forward silently skips or repeats records. Keyset pagination instead carries an opaque cursor encoding the last row's sort key(s); the next page is a range scan from that key. It is stable under concurrent writes and its cost is constant per page regardless of depth. Reserve offset/limit for sets that are small, bounded, and not concurrently mutated (a fixed lookup table, an admin screen over tens of rows) where deep paging never happens.

11. **The cursor is opaque and self-describing.** Clients receive a token and echo it back; they never construct it. It encodes exactly the tuple the sort orders by (rule 13) plus the tiebreak key, so the server can resume deterministically. An opaque cursor is forward-compatible — the server can change its internal encoding without a breaking contract change — and it prevents clients from minting arbitrary offsets into the data.

12. **List responses use one envelope across every collection endpoint:** an `items` array plus a `page` object carrying the forward cursor (and, where supported, the backward cursor) and a `has_more` flag. The shape is uniform so a generic client pages any resource the same way:

    ```jsonc
    // shape: items is the page of resources; page.next_cursor is null when exhausted;
    // page.has_more is the same signal as a non-null next_cursor; total is optional (rule 15)
    {
      "items": [ /* resources */ ],
      "page": {
        "next_cursor": "b3BhcXVl...",
        "has_more": true
      }
    }
    ```

    The page size is a request parameter with a declared **default and a hard maximum** the server clamps to — an unbounded `limit` is a denial-of-service lever, and the maximum is a per-project number set from the route's latency budget (`_spines/performance.md`).

13. **Filtering is a fixed allowlist of fields, each with declared operators — never arbitrary query passthrough.** The contract enumerates exactly which fields are filterable and which operators each accepts (equality, range, set-membership, prefix), and the handler rejects anything off the list. Passing client-supplied field names or predicates straight into the query is both an **injection surface** and an **unbounded performance surface**: a caller could filter on an unindexed column and table-scan the store at will. Every allowlisted filter field is one the data model indexes for that access pattern (`03-design/data-modeling.md`) — the allowlist and the index set are the same decision made once.

14. **Sorting is an allowlist of sort fields with a deterministic tiebreak.** Only enumerated fields are sortable, and every sort is made total by appending the surrogate primary key (`03-design/data-modeling.md` rule 4) as the final tiebreak — without it, rows sharing a sort value have undefined relative order, which makes keyset pagination skip or repeat them and makes results non-reproducible. **Null ordering is declared, not left to the engine's default** (engines disagree on whether nulls sort first or last): the contract states nulls-first or nulls-last per sortable field so the order is stable across stores and across upgrades. As with filters, each sort field is backed by an index that matches the sort direction and the tiebreak (`03-design/data-modeling.md`, `_spines/performance.md`).

15. **A total count over a large table is expensive — estimate it or omit it.** An exact `COUNT(*)` under a filter scans every matching row on each request; on a large or hot table that is a per-page full or index scan that does not scale, and it defeats the constant-cost property keyset pagination just bought. Default to **no total**: `has_more` (rule 12) is enough to drive "next page" and "load more" UIs. Where a count is genuinely needed, prefer an **estimate** (the planner's row estimate, or a periodically materialized count) and label it as approximate in the contract; reserve an exact count for sets already known to be small and bounded.

## Standards basis

- **RFC 9110 — HTTP Semantics** (Internet Standard, STD 97, https://www.rfc-editor.org/rfc/rfc9110): method safety/idempotency and status-code meaning. Basis for rule 6 and the method/idempotency section — transport carries the failure class; methods are used per their defined semantics.
- **RFC 9457 — Problem Details for HTTP APIs** (`application/problem+json`; obsoletes RFC 7807): the standard machine-readable error body. The house envelope satisfies the same intent (stable machine code + human message + structured details); external APIs align to Problem Details verbatim per rule 6.
- **JSON Schema 2020-12** + **OpenAPI 3.1** (https://spec.openapis.org/oas/v3.1.2.html, which adopts JSON Schema 2020-12 as its Schema Object dialect): schema-first contracts with types derived from one schema. Grounds the contract-first principle (rules 1–3) and the single shared contract module; the stack's validation library is the concrete JSON-Schema-equivalent.
- **Richardson Maturity Model / Fielding REST**: resource-oriented URLs, HTTP verbs as the uniform interface, status codes as protocol-level signalling — the target maturity the method/status rules encode.
- **SemVer** (https://semver.org) for evolution: additive = minor (backward-compatible), removal/semantic change = major (breaking). Grounds rules 7–9's additive-is-free / expand→migrate→contract versioning.
- **Google AIP-158 — Pagination** (https://google.aip.dev/158): the standard request/response contract for list methods — a `page_size` with a server-enforced maximum, an opaque `page_token` the client echoes (never constructs), and an empty `next_page_token` signalling the last page. Direct basis for the opaque-cursor envelope of rules 11–12 and the clamped page size; AIP-159 (reserved/range reads) and the broader AIP-132 (Standard List) corroborate the list-method shape.
- **Keyset (seek-method) pagination** — the well-established alternative to `OFFSET`: page by a `WHERE (sort_key, id) > (:last_sort, :last_id)` range scan over an index instead of skipping rows, giving depth-independent cost and stability under concurrent inserts/deletes. Documented in PostgreSQL's indexing/`ORDER BY ... LIMIT` query patterns (the planner serves it as an index range scan) and articulated in Markus Winand's "SQL Performance Explained" / use-the-index-luke.com pagination guidance. Basis for rules 10–11 and 14 (the tuple-comparison cursor and total sort order). The cost of unfiltered `COUNT(*)` over large tables and the use of the planner's row estimate (`pg_class.reltuples` / `EXPLAIN`) as an approximate alternative — basis for rule 15 — are described in the PostgreSQL documentation (Row Estimation, Aggregate Functions).
- **REST collection conventions** — Fielding's REST / the Richardson Maturity Model (above) treat a collection as a resource whose representation is a bounded page with links to sibling pages; **RFC 8288 (Web Linking)** standardizes the `rel="next"`/`rel="prev"` relations that express forward/backward cursors at the HTTP layer. Grounds the uniform list envelope (rule 12) and the allowlist discipline for filter/sort parameters (rules 13–14) as a resource-oriented, link-driven collection contract rather than ad-hoc query passthrough.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (typecheck job — shared inferred types make front/back drift a compile error; test job — boundary parsing and error-envelope assertions)
- Fallback if unenforceable: n/a — type drift and schema bypasses surface in the type check and the boundary-validation tests the testing strategy requires.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the stack's validation library and the typecheck CI job are injected via the preset; this doc defines the shapes they enforce).
