# Flow-back Log

The library's memory of what real projects taught it. Every finding a consuming project records in its debt-log "Library flow-back" section (see `08-maintenance/debt-log.template.md`) lands here with an explicit **disposition** — no finding is silently dropped. This is the durable, cross-project ledger that `00-governance/standards-lifecycle.md` §6 (the feedback loop) feeds; `scripts/check-flowback.sh` validates its integrity on every push/PR via suite CI.

**How an entry flows:** project debt-log finding → reviewed during a currency pass or ad-hoc → row added here with a disposition → if `patched`, the change ships under a tag named in the row (doc↔config same-commit per root `CLAUDE.md`); if `deferred`, the row carries a trigger for when to revisit; if `no-change`, a one-line reason.

Disposition values: `patched` (names the tag that shipped the fix) · `deferred` (carries a revisit trigger) · `no-change` (carries a reason).

| ID | Surfaced | Source project | Finding | Disposition | Tag / commit | Status |
|---|---|---|---|---|---|---|
| FB-01 | 2026-06-08 | stash | `env.schema.example` used zod-3 string APIs (`z.string().url()`); Better Auth 1.6.x requires zod 4, whose string formats are top-level (`z.url()`). A current-stack project must adapt the schema. | patched | v2026.06.9 | closed |
| FB-02 | 2026-06-08 | stash | `vitest.config.example.ts` counted `app/**`+`db/**` in the unit-coverage denominator, but the testing split routes Server Components / live DB client / auth seam to Playwright/integration — making the 70% unit gate unreachable-by-design. | patched | v2026.06.9 | closed |

## Notes

- **Patched** rows must name a tag that exists in the repo's `git tag` list — `check-flowback.sh` enforces this, so a "fixed" claim can't outrun the actual release. (Release ordering, like a changelog: commit the fix + this row, cut the tag, then push commit and tag together — `git push --follow-tags` — so CI never sees a patched row whose tag is absent.)
- **Deferred** rows must carry a non-empty revisit trigger (same data-driven discipline as calibration triggers); the currency pass walks them.
- The library cannot enumerate where consuming projects live, so harvesting findings *into* this log is a manual currency-pass step (`standards-lifecycle.md` §6): for each known project, diff its debt-log "Library flow-back" section against the rows here and add any missing finding.
- A finding that also moved a calibration knob gets a paired row in `calibration.md`'s Observations section (e.g. FB-02 ↔ the coverage-include observation).
