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

## Standards basis

- **RFC 9110 — HTTP Semantics** (Internet Standard, STD 97, https://www.rfc-editor.org/rfc/rfc9110): method safety/idempotency and status-code meaning. Basis for rule 6 and the method/idempotency section — transport carries the failure class; methods are used per their defined semantics.
- **RFC 9457 — Problem Details for HTTP APIs** (`application/problem+json`; obsoletes RFC 7807): the standard machine-readable error body. The house envelope satisfies the same intent (stable machine code + human message + structured details); external APIs align to Problem Details verbatim per rule 6.
- **JSON Schema 2020-12** + **OpenAPI 3.1** (https://spec.openapis.org/oas/v3.1.2.html, which adopts JSON Schema 2020-12 as its Schema Object dialect): schema-first contracts with types derived from one schema. Grounds the contract-first principle (rules 1–3) and the single shared contract module; the stack's validation library is the concrete JSON-Schema-equivalent.
- **Richardson Maturity Model / Fielding REST**: resource-oriented URLs, HTTP verbs as the uniform interface, status codes as protocol-level signalling — the target maturity the method/status rules encode.
- **SemVer** (https://semver.org) for evolution: additive = minor (backward-compatible), removal/semantic change = major (breaking). Grounds rules 7–9's additive-is-free / expand→migrate→contract versioning.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (typecheck job — shared inferred types make front/back drift a compile error; test job — boundary parsing and error-envelope assertions)
- Fallback if unenforceable: n/a — type drift and schema bypasses surface in the type check and the boundary-validation tests the testing strategy requires.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the stack's validation library and the typecheck CI job are injected via the preset; this doc defines the shapes they enforce).
