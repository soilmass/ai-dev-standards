# Security & Privacy Spine

Security is not a layer — it's a property every layer either upholds or leaks. This spine doesn't duplicate the layer rules; it shows **where security bites in each layer**, owns the cross-cutting rules no single layer can, and carries the data-privacy baseline.

## Where it bites, layer by layer

| Layer | Security obligation | Lives in |
|---|---|---|
| 02 Product | Specs for auth/money/PII features carry security acceptance criteria (unhappy paths, enumeration, abuse) | `02-product/acceptance-criteria.md` |
| 03 Design | Per-feature **threat model** before building qualifying features; error envelopes that leak no internals | `03-design/threat-model.template.md`, `03-design/api-contract-design.md` rule 5 |
| 04 Build | Boundary validation of all external input; **secrets never in git** (staged scan + history scan); boot-validated env | `04-build/secrets-config.md`, `04-build/coding-standards.md` rule 9 |
| 05 Verification | Secret scan and dependency audit as required PR checks; security-relevant fallbacks in the self-review checklist | `05-verification/ci-pipeline.md`, `05-verification/code-review-standard.md` §C |
| 06 Delivery | Forward-only reviewed migrations (no schema drive-by); per-environment secrets; kill switches for risky integrations | `06-delivery/migration-discipline.md`, `06-delivery/rollback.md` rule 6 |
| 07 Operations | No secrets/PII in logs; secret **rotation** (below); restore-verified backups as the ransomware/corruption floor | `07-operations/observability.md` rule 5, `07-operations/backup-dr.md` |
| 08 Maintenance | **CVE patching**: security updates land immediately; unfixable vulns get pin-and-mitigate ADRs with expiry | `08-maintenance/dependency-updates.md` rule 2, `04-build/dependency-policy.md` rule 9 |

## Cross-cutting rules owned here

1. **Auth checks live at the resource, not the road.** Session/permission verification happens in the handler or server component that serves the data; middleware and route grouping are convenience layers, never the boundary. This is the durable principle behind governance guardrail 3 (CVE-2025-29927, the spoofable-middleware-header bypass — `00-governance/agent-operating-rules.md` §5): the specific CVE is patched, the design rule outlives it.
2. **Least privilege everywhere:** DB roles, API tokens, and host permissions get the minimum scope that works; the app's runtime credentials can't drop tables it only reads.
3. **Rotation:** any credential is rotatable without a deploy (env-injected, never baked into builds); rotate on schedule (yearly floor), on any suspicion, and **immediately** when a secret ever touched git (`04-build/secrets-config.md` rule 8).
4. **Dependencies are attack surface:** the allowlist, audit gate, and immediate security updates are the supply-chain posture; an agent may never add a dependency unilaterally.

## Data privacy & PII baseline

5. **Classify at design time:** every stored field is public / internal / PII / credentials-or-payment — the threat model template forces the question per feature.
6. **Minimize:** collect only fields with a named use; "might be useful" is not a use. Don't store what you can derive; don't retain what you no longer need (retention rides the backup ladder, `07-operations/backup-dr.md`).
7. **PII handling:** identify users by opaque ID in logs/analytics; PII never in URLs, error messages, or third-party telemetry; encrypted in transit always and at rest via the managed store's encryption.
8. **User rights:** deletion/export requests must be technically satisfiable — soft-delete and backup design account for erasure (hard-delete path exists; backups age out on the retention ladder).
9. **Breach reality:** if user data may have been exposed, the incident runbook's postmortem includes notification obligations assessment — decided with the law applicable to the project, not improvised.

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/pre-commit (staged secret scan) + stacks/nextjs-default/ci/pr.yml (secrets, deps jobs) — the mechanical subset; each layer row above names its own gate
- Fallback if unenforceable: n/a — mechanical pieces are gated in their layers; judgment pieces ride the threat-model and security fallback lines already in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: nothing additional — the hooks, CI jobs, env schema, and threat-model template it already injects are this spine's enforcement surface.
