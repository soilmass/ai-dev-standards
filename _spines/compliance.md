# Compliance Spine

Compliance is not a layer — a framework like SOC 2 or ISO 27001 asks "show me the control, and the evidence it operated," and the answer is spread across security, privacy, audit logging, backups, change management, and vendor management. This spine doesn't duplicate those rules; it **maps the controls a framework expects onto the standards that already satisfy them**, makes evidence a byproduct of running the system, and names — honestly — the controls not yet met. It turns "are we SOC 2 / ISO ready?" from a scramble into a lookup.

## Where it bites — control family → the standard that satisfies it

| Control family (SOC 2 TSC / ISO 27001 Annex A) | Satisfied by | Evidence |
|---|---|---|
| Access control & least privilege (CC6 / A.5.15–18, A.8.2–3) | `_spines/security-privacy.md` (auth at resource, least privilege, rotation) | branch/role config, rotation log |
| Change management (CC8 / A.8.32) | `_spines/version-control.md` (PRs, required checks, signed commits, branch+tag protection), `06-delivery/release-process.md` | PR history, CI run logs, protection settings |
| Secure SDLC (CC8 / A.8.25–28) | `04-build/coding-standards.md`, `05-verification/code-review-standard.md`, `03-design/threat-modeling.md`, `04-build/static-analysis.md` (SAST + image scanning) | review checklist, threat models, CodeQL findings, image-scan reports |
| Vulnerability & patch mgmt (CC7 / A.8.8) | `04-build/dependency-policy.md`, `08-maintenance/dependency-updates.md`, `04-build/supply-chain.md` (SBOM) | audit gate logs, Dependabot PRs, SBOMs |
| Data protection & privacy (CC6 / privacy criteria / A.5.34, A.8.10–12) | `03-design/data-privacy.md` (classification, retention, DSR) | PII map, retention register, DSR test |
| Logging & monitoring (CC7 / A.8.15–16) | `07-operations/observability.md`, `07-operations/audit-log-retention.md` | audit-log retention policy, alert config |
| Availability & resilience (A1 / A.5.29–30, A.8.13–14) | `07-operations/slo-error-budgets.md`, `07-operations/backup-dr.md`, `_spines/reliability.md` | SLO doc, verified-restore log, DR drill record |
| Incident management (CC7 / A.5.24–28) | `07-operations/incident-runbook.template.md`, `07-operations/oncall-escalation.md` | runbooks, postmortems |
| Vendor / supplier risk (CC9 / A.5.19–23) | `04-build/third-party-integrations.md` (ADR + DPA/BAA) | integration ADRs, signed DPAs |
| Risk assessment (CC3 / A.5.* clause 6) | `03-design/threat-modeling.md`, `08-maintenance/tech-debt-policy.md` | threat models, risk/debt log |

## Cross-cutting rules owned here

1. **Pick the framework, then map — don't build controls twice.** Compliance scope is a decision (SOC 2 Type II, ISO 27001, HIPAA, PCI) recorded as an ADR; the work is *mapping* its controls to the table above and closing the named gaps, not inventing a parallel control set. The library's existing standards already implement most of a baseline.
2. **Evidence is a byproduct of running the system, not a quarterly fire drill.** The audit trail (`07-operations/audit-log-retention.md`), CI run history, PR/review records, SBOMs, verified-restore log, and threat models *are* the evidence — generated continuously because the standards run continuously. If a control's evidence has to be reconstructed at audit time, the control isn't really operating.
3. **Unmet controls are tracked openly, never papered over.** A compliance program states what it does **not** yet satisfy, and closes the load-bearing gaps. The secure-SDLC controls a framework expects — **SAST** and **published-artifact (image) scanning** — are now satisfied by `04-build/static-analysis.md` (CodeQL on every PR; Trivy on the container image). What remains genuinely deferred is recorded in `00-governance/completeness-matrix.md` Known gaps (e.g. IaC misconfiguration scanning is reference-only until a project adopts IaC; chaos/experimentation are post-traffic). Naming a remaining gap is the control working as intended (CC3 risk assessment), not a failure to hide.
4. **A control without an owner and a cadence is theater.** Each in-scope control has someone accountable and a review rhythm (the quarterly sweep already in `08-maintenance/tech-debt-policy.md` and the currency pass); "accepted/again-confirmed" is recorded, the same discipline as accepted risk.

## Standards basis

- **AICPA SOC 2 — Trust Services Criteria** (CC-series Common Criteria across Security, plus Availability/Confidentiality/Processing-Integrity/Privacy): the control families in the table map to the TSC; the basis for rules 1–2.
- **ISO/IEC 27001:2022 + Annex A** (the ISMS clauses 4–10 and the 93 Annex A controls in four themes — Organizational/People/Physical/Technological): the second framework the table maps to; clause 6 (risk assessment) grounds rule 3, clause 9–10 (monitoring, improvement) ground rule 4.
- **NIST SSDF (SP 800-218)** and **NIST CSF 2.0** — the secure-development practices (PW/PS/RV) behind the secure-SDLC row and the SAST gap in rule 3; CSF functions (Identify/Protect/Detect/Respond/Recover) align with the control families.
- Builds on every standard named in the table; this spine adds only the framework mapping, the evidence-as-byproduct rule, and the honest unmet-controls register — it owns no control itself.

## Enforcement
- Mechanism: none-possible
- Config: n/a — each mapped control is gated (or review-carried) in its own standard; this spine is the framework map and evidence index.
- Fallback if unenforceable: For a compliance-scoped change, confirm the affected control still holds and its evidence is captured by the running system (audit log, CI/PR history, SBOM, restore log, threat model) — not reconstructed later; any control the change cannot satisfy is recorded as an open gap with an owner.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the framework choice and control mapping are per-project; the audit-log, backup, dependency, and threat-model surfaces that produce the evidence are injected by their own standards).
