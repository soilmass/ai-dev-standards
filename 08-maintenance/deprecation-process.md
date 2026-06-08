# Deprecation Process

How features, APIs, flags, and schema fields sunset. Deletion is the goal — deprecation is the safe path there, and "deprecated forever" is just debt wearing a sign.

## The sequence

Every removal follows the same four steps, scaled to its blast radius:

1. **Mark.** The deprecated thing gets an explicit marker at its declaration (the language's deprecation annotation, a deprecation comment with date and replacement; for external HTTP API surfaces the `Deprecation` response header per RFC 9745, with a `Link` `rel="deprecation"` pointing at the migration docs) plus a pointer to the replacement. From this moment, new usage is a review violation.
2. **Announce & migrate.** Internal consumers are migrated by the same PR series that deprecates (expand → migrate → contract, `03-design/api-contract-design.md` rule 8). External consumers — if any — get the change announced in the changelog **and** a machine-readable removal date: the `Sunset` response header per RFC 8594. The date respects how fast consumers can realistically move, and the deprecation period precedes it (the `Deprecation` timestamp is in the past or now; `Sunset` is in the future).
3. **Verify silence.** Before removal: prove non-use. Internal — the type checker and a search show zero references. External/data — telemetry shows zero calls over a full usage cycle (`07-operations/observability.md` makes this answerable); for schema fields, the data-modeling destructive-change rules apply (`03-design/data-modeling.md` rule 13).
4. **Remove.** Delete the code, the flag, the field, the docs, and the debt-log row in one PR. A removal that leaves the docs describing the dead feature fails the docs-updated gate.

## Scope notes

- **Feature flags** are pre-registered for deprecation at birth: each has a removal condition (`06-delivery/release-process.md` rule 8); a 100%-on flag past one release cycle triggers this process automatically.
- **Standards in this library** sunset through their own lifecycle (`00-governance/standards-lifecycle.md` §5), which mirrors this sequence.
- **Dependencies** are removed the quarter they stop being imported (`04-build/dependency-policy.md` rule 10).

## Agent rules

- An agent finding deprecated usage while working nearby migrates it if trivial (same-PR, within size budget) or logs it as triggered debt — it never adds new usage of a marked-deprecated surface.
- Deleting an externally consumed surface is ask-first, always.

## Standards basis
- **SemVer 2.0.0** (semver.org) — deprecating any public-API surface MUST ship in a MINOR release, and at least one such release MUST carry the deprecation *before* the MAJOR that removes it; removal is a breaking change → MAJOR. This is the version-level shape of the four-step sequence.
- **RFC 9745 — The Deprecation HTTP Response Header Field** (rfc-editor.org/rfc/rfc9745, Proposed Standard, March 2025; obsoletes the long-standing `Deprecation` I-D) — signals a resource is/will be deprecated via a structured-field Date timestamp, and pairs with a `Link rel="deprecation"`. The presence of the header does not change the resource's behavior — consumers keep working until Sunset, which is why Mark precedes Remove.
- **RFC 8594 — The Sunset HTTP Header Field** (rfc-editor.org/rfc/rfc8594, Informational) — advertises the point in time after which a URI is expected to stop responding (IMF-fixdate), plus a `sunset` link relation; this is the machine-readable removal date in step 2 and the precondition the "verify silence" step measures against.
- **Graceful degradation / expand-contract (parallel-change)** — deprecate-then-migrate-then-remove (Mark → Migrate → Verify silence → Remove) is the parallel-change pattern applied to lifecycle: never break a live consumer; prove non-use before deletion.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this change deprecates an API, route, flag, or schema field, it adds the deprecation marker and migration note instead of deleting outright.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only.
