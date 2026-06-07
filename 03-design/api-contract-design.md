# API Contract Design

Contracts before handlers: the shape of every API is declared as a schema first, and both sides consume that declaration. This is what keeps the front and back ends from drifting — especially when different agent runs build each side.

## Contract-first principle

1. Every endpoint/action declares its input schema and output schema **before** implementation, in the validation library the stack pins. The schema is the contract; the handler implements it.
2. Types are **inferred from the schemas** and shared front↔back from one module — never hand-duplicated interface declarations on each side. One declaration, both directions.
3. Handlers parse input through the schema at the boundary (reject early, typed thereafter) and — in development and tests — validate output against the response schema too.

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
6. Transport status (HTTP) carries the class of failure; `error.code` carries the specifics. Both are asserted in tests.

## Versioning & evolution

7. **Additive changes are free** (new optional fields, new endpoints). Anything else — removing/renaming fields, tightening types, changing semantics — is breaking.
8. Breaking changes follow expand → migrate → contract: ship the new shape alongside the old, move consumers, then retire the old shape on a stated schedule (`08-maintenance/deprecation-process.md`).
9. Internal app APIs (same repo, one consumer) need no version namespace — the type system is the migration tool. Externally consumed APIs get explicit versioning from day one.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (typecheck job — shared inferred types make front/back drift a compile error; test job — boundary parsing and error-envelope assertions)
- Fallback if unenforceable: n/a — type drift and schema bypasses surface in the type check and the boundary-validation tests the testing strategy requires.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the stack's validation library and the typecheck CI job are injected via the preset; this doc defines the shapes they enforce).
