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

## Standards basis

- **OWASP Top 10:2025** (owasp.org/Top10/2025) — the consensus most-critical web risks. This spine's posture maps directly: A01 Broken Access Control → rule 1 (auth at the resource) + rule 2 (least privilege); A02 Security Misconfiguration → boot-validated env, per-environment secrets; **A03 Software Supply Chain Failures** (new, elevated from 2021's A06) → rule 4 (deps as attack surface: allowlist + audit gate + immediate updates); A07 Authentication Failures → resource-level checks; A09 Security Logging and Alerting Failures → no secrets/PII in logs + observability; **A10 Mishandling of Exceptional Conditions** (new) → error envelopes that leak no internals.
- **OWASP ASVS 5.0** (May 2025, asvs.dev) — verification requirements by chapter (V2 Authentication, V4 Access Control, V6 Stored Cryptography, V8 Data Protection, V14 Configuration). The per-feature security acceptance criteria and the classify/minimize/PII rules below operationalize ASVS V8/V14 at design time.
- **OWASP Proactive Controls 2024** (top10proactive.owasp.org) — developer-facing techniques: C1 access control, C3 validate all input (boundary validation, layer 04), C2 cryptography, C8 secure secrets handling. Ordered controls, not just vulnerabilities.
- **OWASP SAMM** — security maturity model framing the threat-modeling-before-build cadence as a Design-domain practice, not an afterthought.
- **NIST SSDF (SP 800-218 v1.1)** — four practice groups PO/PS/PW/RV; this spine realizes PW.4 (boundary validation), PS.1 (secrets out of source), PW.7/PW.8 (review + test), and RV.* (CVE patching, layer 08). (SSDF v1.2 in public draft per EO 14306, Dec 2025 — not yet final.)
- **SLSA v1.0 Build Track** (slsa.dev/spec/v1.0) — provenance levels L1–L3 for supply-chain integrity; the supply-chain posture (rule 4) targets verifiable build provenance and tamper-resistance, aligning A03 / OWASP A08 (integrity).
- **CIS Benchmarks** — vendor-neutral secure-configuration baselines for hosts/containers/cloud; the least-privilege and managed-store-encryption rules track CIS hardening guidance.
- **GDPR Art. 5 principles** — data minimization (Art. 5(1)(c)), purpose limitation (Art. 5(1)(b)), storage limitation (Art. 5(1)(e)), integrity/confidentiality (Art. 5(1)(f)); these are the basis for rules 6–7. Privacy-by-design (GDPR Art. 25 / Cavoukian's 7 foundational principles) is why classification (rule 5) happens at design time, not retrofit. User rights (rule 8): GDPR Arts. 15/17 (access/export, erasure). Breach notification (rule 9): GDPR Arts. 33/34.
- **NIST Privacy Framework** (Identify-P / Govern-P / Control-P / Communicate-P / Protect-P) — CT.DM (Data Minimization) mandates collect-only-what's-needed, defined retention, scheduled deletion; this is the framework form of rules 6–8. (PFW 1.1 in initial public draft, Apr 2025; 1.0 remains current.)

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/pre-commit (staged secret scan) + stacks/nextjs-default/ci/pr.yml (secrets, deps jobs) — the mechanical subset; each layer row above names its own gate
- Fallback if unenforceable: n/a — mechanical pieces are gated in their layers; judgment pieces ride the threat-model and security fallback lines already in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: nothing additional — the hooks, CI jobs, env schema, and threat-model template it already injects are this spine's enforcement surface.
