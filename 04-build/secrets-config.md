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

## Standards basis

- **12-Factor App — Factor III (Config)** (https://12factor.net/config) — strict separation of config from code, config stored in the environment, no secrets in the repo: the founding principle for the env-schema and never-commit sections (rules 1–6).
- **OWASP Secrets Management Cheat Sheet** (https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html) — keep secrets out of source/logs, scan for leaks, prefer short-lived secrets with defined expiry, and treat any leaked secret as compromised → rotate then remediate: grounds rules 6–8, 10. Aligned: "rotation first, history rewriting is cosmetic."
- **NIST SP 800-57 Part 1 Rev. 5 (Key Management)** (https://csrc.nist.gov/pubs/sp/800/57/pt1/r5/final) — every key has a bounded *cryptoperiod* sized to sensitivity and exposure; compromise triggers immediate revocation/re-key. The basis for the per-environment rotation cadence (rule 11; procedure in `_spines/security-privacy.md`).
- **OWASP ASVS 5.0 — V6 Stored Cryptography & V14 Configuration** (May 2025, https://owasp.org/www-project-application-security-verification-standard/) — V6 mandates secrets held in a managed secret store with controlled creation/destruction; V14 mandates secure, validated, environment-segregated configuration. Grounds the boot-validation (rules 2–3) and per-environment isolation (rule 11) requirements.

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/pre-commit (gitleaks staged scan) + stacks/nextjs-default/ci/pr.yml (secrets job: full-history scan; build job: boot-validation of the env schema) + stacks/nextjs-default/env.schema.example (runtime check)
- Fallback if unenforceable: n/a — scanning and boot validation are mechanically enforced; log-redaction discipline is covered by the observability fallback line.

## Bootstrap
- What new-project.sh injects for this standard: `env.schema.ts` (from `env.schema.example`), the pre-commit hook with the staged secret scan, and the CI jobs that re-scan and boot-validate.
