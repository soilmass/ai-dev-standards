# Audit-Log Retention & Compliance

`observability.md` covers operational logs — the telemetry you query to keep the system healthy and throw away in days. This doc covers **audit logs**: the deliberate, durable, tamper-evident record of who did what to whom, kept long enough to answer an investigation or a regulator months later. They are a different artifact with different rules: where operational logs optimize for volume and recency, audit logs optimize for integrity and retention.

## What is an audit event

1. **Security- and trust-relevant actions are audited as first-class events**, distinct from debug logging: authentication (success *and* failure), authorization decisions and denials, privilege/role changes, password/MFA/credential changes, access to or export of sensitive data, administrative actions, and changes to the audit configuration itself. If an action would matter in an incident or a dispute, it is an audit event.
2. **Every audit record carries the irreducible five W's:** who (actor identity), what (action + outcome, allow/deny), when (trusted UTC timestamp), where (source — IP/session/request ID), and on-what (target resource). A record missing the actor or the outcome can't answer the question the log exists for.
3. **Audit events are emitted from the trust boundary, server-side, not reconstructed from app logs.** The handler that authorizes the action writes the audit record (`_spines/security-privacy.md`) — a client-supplied or after-the-fact reconstruction is exactly what an attacker would forge.

## Integrity — the log must be trustworthy

4. **Audit logs are append-only and tamper-evident.** The store does not permit in-place edits or selective deletes by the application; integrity is provable (hash-chained/sequenced records, a WORM or write-once retention tier, or a managed append-only audit service). A log an attacker (or a panicked operator) can quietly rewrite proves nothing in an investigation.
5. **The audit path is separated from the data it watches.** Privileged users of the application are not, by default, able to alter or purge its audit trail — ship audit records to a store with a different access boundary (separate sink/account/retention lock). Self-auditing that the audited party can erase is theatre.
6. **Audit writes fail loudly.** If the audit sink is unavailable, that is an error that surfaces (and, for the highest-sensitivity actions, may block the action) — never a silently dropped record. A gap in the trail is itself a security event.

## Retention — long enough, not longer

7. **Security-relevant audit logs have a defined retention period set by the binding requirement, with a sane floor.** Absent a stricter regulation, retain at least one year, with the recent window (≈90 days) immediately queryable — the PCI DSS Req 10 baseline, a widely applicable default. Sectoral or contractual rules (PCI, SOC 2, HIPAA, financial records) override upward; the chosen period and its driver are recorded, not assumed.
8. **Retention is bounded on both ends — minimum *and* maximum.** Storage limitation still applies (`03-design/data-privacy.md` rule 8): keep audit logs as long as the obligation requires and then dispose of them. "Keep everything forever" is an unbounded PII liability, not diligence. The maximum is a decision someone signs.
9. **Retention is enforced by an automated lifecycle, not by hope.** A scheduled/lifecycle policy on the audit store ages records to cold storage and then deletes (or anonymizes) them at the boundary — the same "enforced by a job, not by intention" rule as data retention (`03-design/data-privacy.md` rule 9). A retention policy with no expiry mechanism is fiction in the other direction.

## Compliance & privacy tensions

10. **Audit logs hold PII and must minimize it.** They name actors and targets, so they are personal data: identify subjects by opaque ID, never write the secret/credential/payload being changed (log "password changed", never the password), and keep the record to the five W's. The audit log is not an excuse to stockpile sensitive values "for completeness".
11. **The erasure right meets a lawful-retention exception, and you encode which wins.** A GDPR erasure request (`03-design/data-privacy.md`) does not automatically wipe an audit trail the law requires you to keep (GDPR Art. 17(3)(b)); conversely you can't keep audit PII past its purpose just because it's labelled "audit". Record, per audit stream, whether a legal-hold exception applies and its expiry — the same encode-the-exception discipline as the privacy doc.
12. **Audit completeness is part of incident readiness.** During an incident (`07-operations/incident-runbook.template.md`) the audit log is the primary forensic source; a missing or unmonitored audit trail is itself the failure (OWASP A09:2021, Security Logging & Monitoring Failures). Confirm the events that would matter are actually being captured *before* you need them — an untested audit trail is the logging equivalent of an unrestored backup.

## Standards basis

- **NIST SP 800-92 — Guide to Computer Security Log Management** (csrc.nist.gov): log generation, protection, and retention as a managed lifecycle; the basis for the integrity (rules 4–6) and retention-lifecycle (rules 7–9) framing.
- **OWASP Top 10 — A09:2021 Security Logging & Monitoring Failures** and the **OWASP Logging Cheat Sheet / ASVS V7 (Logging & Error Handling)**: *what* to audit (rule 1), the required fields (rule 2), no-secrets-in-logs (rule 10), and tamper protection — grounds most of this doc.
- **PCI DSS v4.0 Requirement 10** (pcisecuritystandards.org): the concrete retention baseline behind rule 7 — audit history retained **≥ 1 year** with **≥ 3 months immediately available** — plus the requirement that audit trails be protected from alteration (rule 4).
- **GDPR Art. 5(1)(e) storage limitation + Art. 17(3) erasure exceptions** (gdpr-info.eu): the two-sided retention bound (rule 8) and the erasure-vs-legal-hold resolution (rule 11).
- **ISO/IEC 27001:2022 Annex A — A.8.15 Logging / A.8.16 Monitoring activities**: event logging, log protection, and clock synchronization as controls — corroborates rules 1–6 at the ISMS level.
- Extends `07-operations/observability.md` (operational vs. audit logs are different artifacts), bounded by `03-design/data-privacy.md` (PII, retention, DSR) and `_spines/security-privacy.md` (the security obligations that produce the auditable actions), and consumed by `07-operations/incident-runbook.template.md` (forensics).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Security/trust-relevant actions emit append-only, tamper-evident audit records carrying actor/action+outcome/timestamp/source/target with no secrets or raw PII; the audit store has a different access boundary from what it audits; and each audit stream has an automated retention lifecycle with a defined minimum (binding requirement, ≥1y floor) and maximum.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the audit sink, its retention/immutability policy, and the regulatory driver are per-project choices recorded as an ADR; the incident-runbook template it injects consumes the audit trail this doc produces).
