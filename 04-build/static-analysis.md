# Static Analysis & Image Scanning

The pipeline already scans **secrets** (gitleaks) and **dependencies** (audit + dependency-review + SBOM); this doc adds the missing security layer — **static analysis of your own code** (SAST) and **vulnerability scanning of the artifact you ship** (the container image). Together they close the secure-SDLC controls that a compliance framework (`_spines/compliance.md`) expects.

## Static application security testing (SAST)

1. **Every PR is statically analyzed for security defects, as a required check.** SAST inspects the source for injection, unsafe deserialization, path traversal, weak crypto, SSRF, and similar CWE-classed flaws that lint and type-checks don't catch — and it gates merge like any other required check (`05-verification/ci-pipeline.md`). The engine is a stack choice (CodeQL in the presets; Semgrep is the documented alternative), recorded as an ADR.
2. **Run the security query suite, not the default.** Use the deeper/security-extended rule set so the analysis finds the vulnerability classes, not just code-quality smells; findings surface in the platform's security dashboard with severity and a remediation path.
3. **A finding is triaged, not ignored.** A true positive is fixed; a false positive is dismissed *with a recorded reason* (the same accept-with-justification discipline as a dependency exception, `04-build/dependency-policy.md`) — never silently muted. SAST is noisy by nature, so the triage discipline is what keeps the gate trusted.

## Image & artifact scanning

4. **A published artifact is scanned before it ships.** Any preset that builds a container image scans it for known OS- and library-layer CVEs and **fails the release on fixable HIGH/CRITICAL** vulnerabilities (`ignore-unfixed` so an unpatchable upstream CVE doesn't block forever, but is still visible). A serverless preset has no image to scan — the SAST + dependency layers are its coverage.
5. **Scan the same digest you attest and deploy.** The scan, the SLSA provenance attestation, and the deploy all reference the one built image digest (`04-build/supply-chain.md`) — scanning a different build than you ship proves nothing.
6. **Infrastructure-as-code is scanned for misconfiguration where it exists.** Projects that adopt IaC add config scanning (tfsec/checkov/trivy-config) as a gate (`06-delivery/infrastructure-as-code.md`); the managed/serverless presets ship no IaC, so this is reference-only until then.

## Standards basis

- **OWASP — SAST & the Top 10** (owasp.org; the Source-Code-Analysis-Tools page) — static analysis as the developer-time control for the injection/access/crypto vulnerability classes; the basis for rules 1–3. Findings map to **CWE** (cwe.mitre.org), the common weakness taxonomy.
- **CodeQL** (codeql.github.com) and **Semgrep** (semgrep.dev) — the query-based SAST engines behind rule 1 (CodeQL in the presets, named as the canonical choice; the engine is a per-project ADR).
- **Trivy** (aquasecurity.github.io/trivy) and **container image scanning** — OS/library CVE scanning of the built image; the basis for rules 4–5. **CIS Benchmarks** and **tfsec/checkov** ground rule 6's IaC misconfiguration scanning.
- **OpenSSF Scorecard** (`SAST`, `Vulnerabilities`, `Fuzzing` checks) and **NIST SSDF (PW.7/PW.8 — review & test)** — the secure-development practices this doc satisfies; complements `_spines/security-privacy.md` and the dependency/supply-chain layer (this doc is *code + image* scanning, those are *secrets + dependencies*).

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (codeql job — SAST, both presets) + stacks/nextjs-container/ci/release.yml (Trivy image scan on the published image)
- Fallback if unenforceable: n/a — SAST is a required PR check and image scanning gates the release; triage of findings rides the dependency-exception discipline in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the CodeQL SAST job (in the injected `pr.yml`, a required check once branch protection is applied) and, for the container preset, the Trivy image scan in `release.yml`.
