# Secrets & Configuration

Configuration is data with a schema; secrets are configuration that must never touch the repo. Both fail loudly at boot, never quietly at request time.

## The env schema — validated at boot

1. Every environment variable the app reads is declared in one schema file (`env.schema.ts` in the preset), with type, constraints, and optionality made explicit.
2. The schema is **validated at boot**: a missing or malformed variable kills startup with a named error. No half-configured process ever serves traffic.
3. Application code imports the parsed env from the schema module (separate server and client exports — server values must be unreachable from client bundles). Direct `process.env` reads elsewhere are a review violation — they bypass validation and typing.
4. Client-exposed variables carry the framework's public prefix and contain no secrets; server-only variables never get the prefix.
5. Optional variables are modeled as optional in the schema — never papered over with runtime fallbacks scattered through the code.

## The never-commit rule

6. Real values live in the local env file (gitignored) and in the host's environment settings — **never in git, in any file, in any commit, ever**. The example/schema files carry shapes and constraints, not values.
7. Secret scanning runs twice: the pre-commit hook scans the staged diff (blocks the commit), and CI scans full history (catches bypasses). Never bypass the hook with `--no-verify`; fix the finding.
8. A secret that ever entered a commit is **compromised**: rotate it immediately, then clean up. Rotation first — history rewriting is cosmetic, not remediation.
9. False positives (high-entropy test fixtures) are waived inline on the specific line with the scanner's allow marker, never by disabling the scan or excluding a path.

## Handling rules

10. Secrets never appear in logs, error messages, exception payloads, or analytics (see `07-operations/observability.md` redaction rules).
11. Each environment (dev/preview/production) has its own secret values; production secrets exist only in the production host's settings. Rotation procedure and cadence: `_spines/security-privacy.md`.

## Rotation operations (the how)

The library mandates *that* secrets rotate — on the cadence and triggers in `_spines/security-privacy.md` rule 3 — but a mandate without a procedure produces outages, because the naive reading ("delete the old value, set the new one") cuts off every in-flight request that authenticated with the old credential. This section is the procedure. Rotation is a controlled overlap, never a hard cutover.

12. **Rotation is a dual-validity window, not a swap.** Issue the new credential first, configure the consumer to accept **both** the old and the new value while in-flight requests and cached sessions drain, and only then revoke the old. At no point is there a single instant where neither the old nor the new credential is valid — that instant is the outage the overlap exists to prevent. A credential type that cannot hold two valid values at once (the provider issues exactly one) is rotated against a brief, announced maintenance window instead, and that limitation is recorded where the secret is classified.
13. **Verify the new credential works before revoking the old.** The new value must be proven against the live dependency it authenticates to — a real authenticated call, not merely "the variable is set" — while the old value is still accepted. Revocation of the old credential is gated on that proof. Revoking first and verifying second turns a typo or a mis-scoped grant into an outage with no fallback.
14. **Rotate and verify in a non-production environment first, then production.** The sequence follows the trust ladder: prove the rotation in a lower-trust environment (against its own scoped, non-production credential per `06-delivery/secrets-promotion.md` section C) before touching production. A rotation procedure that has never run anywhere but production is being tested in production. The lower-environment pass validates the mechanics — the dual-validity overlap, the verification call, the revoke step — so production rotation exercises a known-good procedure, not a new one.
15. **If the new credential fails verification, roll back to the still-valid old one.** Because the old credential was never revoked before the new one was proven (rule 13), rollback is simply "stop using the new value; the old is still accepted" — no scramble to un-revoke. The failed new credential is itself revoked (it may have leaked during the attempt), the cause is fixed, and the rotation is re-attempted from the top. Rollback is the default branch of every rotation, designed in, not improvised.
16. **A partially rotated set is an incident until it converges.** When one environment has been rotated and another has not — production on the new value, preview still on the old; or the reverse — the secret has silently diverged across the set its classification names (`06-delivery/secrets-promotion.md` section D). This is not "mostly done"; it is a configuration-drift fault that must be driven to convergence: finish the unrotated environments, or, if the new credential is bad, roll **every** environment back to the verified old value. The terminal state is the entire classified set on one consistent value — never a stable split.
17. **Compromise collapses the window to immediate revocation.** Scheduled rotation is unhurried and overlap-first; compromise rotation is not. When a secret is known or suspected to be exposed — it touched git (rule 8), appeared in a log or error payload, or left a trusted boundary — the priority inverts: issue and cut over to a new credential and **revoke the exposed one immediately**, accepting the in-flight disruption, because every second the exposed value stays valid is attacker-usable time. The graceful dual-validity drain is a luxury of planned rotation; under compromise, fast revocation of the leaked credential outranks zero-downtime.

## Standards basis

- **12-Factor App — Factor III (Config)** (https://12factor.net/config) — strict separation of config from code, config stored in the environment, no secrets in the repo: the founding principle for the env-schema and never-commit sections (rules 1–6).
- **OWASP Secrets Management Cheat Sheet** (https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) — keep secrets out of source/logs, scan for leaks, prefer short-lived secrets with defined expiry, and treat any leaked secret as compromised → rotate then remediate: grounds rules 6–8, 10. Aligned: "rotation first, history rewriting is cosmetic."
- **NIST SP 800-57 Part 1 Rev. 5 (Key Management)** (https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) — every key has a bounded *cryptoperiod* sized to sensitivity and exposure; compromise triggers immediate revocation/re-key. The basis for the per-environment rotation cadence (rule 11; procedure in `_spines/security-privacy.md`).
- **OWASP ASVS 5.0 — V6 Stored Cryptography & V14 Configuration** (May 2025, https://owasp.org/www-project-application-security-verification-standard/) — V6 mandates secrets held in a managed secret store with controlled creation/destruction; V14 mandates secure, validated, environment-segregated configuration. Grounds the boot-validation (rules 2–3) and per-environment isolation (rule 11) requirements.
- **OWASP Secrets Management Cheat Sheet — rotation guidance** (https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) — beyond the leak-then-rotate posture grounding rules 6–8, its rotation section calls for graceful rollover that supports multiple concurrent valid secrets so consumers can migrate without an availability gap, verification of the new secret before retiring the old, and immediate revocation on compromise: the basis for the dual-validity window (rule 12), verify-before-revoke (rule 13), rollback-to-old (rule 15), and the compromise fast-path (rule 17).
- **NIST SP 800-57 Part 1 Rev. 5 (Key Management) — key-state lifecycle** (https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) — §7 "Key States and Transitions" defines the key states (§7.1–§7.6: pre-activation, active, suspended, deactivated, compromised, destroyed) and the transitions among them; a new key is activated and the old key moves to deactivated (still usable to process already-protected data) before destruction, which is the lifecycle form of the issue-overlap-revoke ordering (rules 12–13). A compromised key transitions to *destroyed* — immediate, not drained (rule 17). The staged, verifiable transitions are why rotation is rehearsed in a lower environment first (rule 14) and why a half-transitioned set is an unstable state to be converged (rule 16).

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/pre-commit (gitleaks staged scan) + stacks/nextjs-default/ci/pr.yml (secrets job: full-history scan; build job: boot-validation of the env schema) + stacks/nextjs-default/env.schema.example (runtime check)
- Fallback if unenforceable: n/a — scanning and boot validation are mechanically enforced; log-redaction discipline is covered by the observability fallback line.

## Bootstrap
- What new-project.sh injects for this standard: `env.schema.ts` (from `env.schema.example`), the pre-commit hook with the staged secret scan, and the CI jobs that re-scan and boot-validate.
