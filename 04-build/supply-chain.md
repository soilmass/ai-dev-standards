# Supply-Chain Security

An attacker who can't breach your app will try to breach what *built* it. This doc governs the integrity of the build itself — provenance, signing, SBOM, and verify-before-trust — for both the artifacts you ship and the artifacts you consume. The CVE/license gate is the *known-vulnerability* side and lives in `04-build/dependency-policy.md` (audit + allowlist) and `08-maintenance/dependency-updates.md` (cadence); this doc is the *build-integrity* side. Producer-side provenance generation is stated as rule 11 there — this doc is the full posture behind it. Do not duplicate the audit/license rules here.

## Target posture

1. The standing target is **SLSA Build Level 2** for every released artifact: built on a hosted, trusted build platform that produces **signed provenance** automatically. L1 (provenance exists but is unsigned/self-generated) is insufficient — unsigned provenance proves nothing under tampering. L3 (isolated, non-falsifiable builds) is the aspiration for high-value artifacts; reach for it where the build platform offers it, but L2 is the floor that blocks a release from being called done.
2. Provenance is generated **in CI, not by a developer's machine** — a local build can attest to nothing an attacker on that machine couldn't forge. The build platform's identity, not a human's, signs it.

## What gets attested

3. Every released artifact carries an **in-toto attestation** bundle: at minimum a **SLSA provenance** predicate (what built it, from which source commit/digest, with which external parameters/inputs). The subject is the artifact's content digest — the attestation binds to *bytes*, not to a tag a publisher can re-point.
4. Attestations are **signed** (keyless/identity-based signing preferred — the signer is the CI workflow's verifiable identity, not a long-lived private key a developer holds). Described vendor-neutrally as *signed provenance/attestations*; the signing tool is a stack choice, not a rule.
5. Provenance is **distributed with the artifact** so a consumer can fetch and verify it without out-of-band coordination — alongside the artifact in the registry, or referenced from it.

## SBOM

6. Every released artifact ships a **Software Bill of Materials** in a standard format — **SPDX** (ISO/IEC 5962) or **CycloneDX** (ECMA-424). Pick one per project and record it in the stack's `stack-decisions.md`; do not hand-maintain a bespoke list.
7. The SBOM is **generated from the resolved dependency graph** (the committed lockfile / built image), in CI, at build time — not authored by hand and not assembled after the fact. It enumerates direct *and* transitive components with versions and, where the format supports it, content hashes.
8. The SBOM is an **input to vulnerability response**, not a compliance artifact you file and forget: when a new CVE lands, the question "are we affected, and where?" is answered by querying SBOMs, not by re-scanning from memory (`08-maintenance/dependency-updates.md`).

## Verify on consume

9. **Trust nothing you didn't verify.** Before an artifact you didn't build enters a build or a deployment — a base image, a published package, a downloaded binary, a third-party action/plugin — verify its provenance and signature against an explicit expectation: expected source repository, expected builder identity, expected signing identity. An artifact that *has* a signature you never check is no safer than one with none.
10. **Pin by digest, not by tag.** Mutable tags (`latest`, a version tag a publisher can move) are not identity. Reference external build inputs — base images, CI actions, pinned binaries — by immutable content digest so the thing you verified is the thing you run. This is the build-input analogue of the lockfile pin in `04-build/dependency-policy.md` rule 4.
11. Verification **failure blocks the build/deploy** — it is a gate, not a warning. A missing, unsigned, or mismatched attestation on a required input fails the pipeline the same way a high-severity CVE does. "Verify but proceed on failure" is theater.

## Build environment integrity

12. The build runs from a **clean, defined environment** with inputs that are pinned and fetched over authenticated channels — no `curl | sh` of an unpinned URL, no implicit "whatever's newest." Treat the build platform's own configuration (workflow files, runner images) as security-relevant code subject to review (`04-build/git-standards.md`, `05-verification/code-review-standard.md`).
13. **Install/post-install scripts are an execution surface**, not a convenience: a dependency that runs code at install time runs it in your build with your credentials (the 2025 self-propagating npm worm spread exactly this way). Prefer ecosystems/settings that disable lifecycle scripts by default; vet any dep that requires them as part of the rule-3 vetting in `04-build/dependency-policy.md`.
14. Evaluate a candidate dependency's *project* security posture, not just its code, before adoption — automated **OpenSSF Scorecard** heuristics (Signed-Releases, Pinned-Dependencies, Dangerous-Workflow, Maintained) give an objective read. This is the same vetting backbone referenced in `dependency-policy.md` rule 3, applied to supply-chain provenance specifically.

## Standards basis

- **SLSA v1.0 — Build Track** (https://slsa.dev/spec/v1.0/levels) — the current (v1.0, build track, levels 0–3) framework. L1 = provenance exists; L2 = hosted build + *signed* provenance; L3 = isolated, non-falsifiable. Grounds the L2 target posture (rules 1–2) and the CI-not-developer generation rule. SLSA v1.0 deferred the source/dependency tracks to future versions, so this doc targets the build track explicitly.
- **in-toto Attestation Framework** (https://github.com/in-toto/attestation) — the Statement/Predicate/Subject model for signed, verifiable supply-chain claims; SLSA Provenance is one predicate type. Grounds the attestation structure and digest-binding (rules 3–5) and the policy-based verification-on-consume model (rules 9, 11).
- **OWASP Top 10:2025 — A03 Software Supply Chain Failures** (https://owasp.org/Top10/2025/A03_2025-Software_Supply_Chain_Failures/) — new #3 category covering compromises in building, distributing, and updating software (expanding the former A06 Vulnerable & Outdated Components beyond just known CVEs). Names the threat class this doc defends — including malicious install scripts and the self-propagating package worm (rule 13).
- **NIST SP 800-218 (SSDF v1.1)** (https://csrc.nist.gov/pubs/sp/800/218/final) — PS.3 mandates collecting and securely sharing provenance data (incl. SBOM) so it stays trustworthy over time; PW/PO cover build-environment integrity. Grounds the provenance + SBOM generation/distribution rules (3–8) and clean-build-environment rule (12).
- **SBOM formats — SPDX** (ISO/IEC 5962:2021; 3.0.1, https://spdx.dev) and **CycloneDX** (ECMA-424, https://cyclonedx.org) — the two standardized, machine-readable SBOM formats; SPDX is license/compliance-leaning, CycloneDX security/attestation-leaning, converging in capability. Grounds the pick-a-standard-format rule (6–7).
- **OpenSSF Scorecard** (https://scorecard.dev) — automated security-health heuristics (Signed-Releases, Pinned-Dependencies, Dangerous-Workflow, Maintained) for evaluating a dependency's project posture before adoption. Grounds rule 14 (and shares the vetting backbone with `dependency-policy.md` rule 3).

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (supply-chain job: CycloneDX SBOM generated + retained, and PR-diff dependency review blocking high+ vulns / disallowed licenses). Build-provenance attestation (SLSA, `actions/attest-build-provenance`) is enforced by presets that publish a built artifact to attest — a serverless deploy has no artifact, so provenance is preset-dependent, not global.
- Fallback if unenforceable: n/a — SBOM + PR dependency review are CI-enforced; build-provenance is CI-enforced wherever a preset publishes an artifact; verify-on-consume / digest-pinning of build inputs (base images, actions) is reviewable in the diff and carried by the standing self-review items.

## Bootstrap
- What new-project.sh injects for this standard: the PR workflow containing the supply-chain job (SBOM + dependency review).
