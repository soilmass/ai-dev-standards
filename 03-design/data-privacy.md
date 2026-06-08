# Data Privacy

Privacy is a design-time property of the data model, not a policy bolted on at launch. This doc governs how personal data is **classified, minimized, retained, and surrendered back to its subject**. It owns the data-subject-rights (DSR) procedures; the security spine (`_spines/security-privacy.md`) owns PII-in-transit/at-rest and breach handling.

## Classification

1. **Every stored field carries one of four classes** — `PUBLIC | INTERNAL | PII | CREDENTIALS_OR_PAYMENT` — the same taxonomy the threat model forces per feature (`03-design/threat-model.template.md`). The class is recorded next to the field in the schema (a comment or annotation), so a reader never has to guess.
2. **PII is anything that identifies a person directly or in combination** — name, email, phone, precise location, device/account identifiers, plus the linkable quasi-identifiers (birthdate + postcode + gender re-identify most people). Pseudonymized data (opaque ID, key held separately) is still personal data; only true anonymization (irreversible) leaves the regime.
3. **A new PII or payment field is a design decision, not a migration footnote.** Adding one requires the feature's threat model to name the field, its class, its lawful purpose, and its retention period before the column ships.

## Minimization & purpose limitation

4. **Collect only fields with a named, current use.** "Might be useful later" is not a use (GDPR Art. 5(1)(c)). The spec's acceptance criteria (`02-product/acceptance-criteria.md`) must justify each PII field, or it isn't built.
5. **Purpose-bind at collection.** Data gathered for one purpose is not silently repurposed (Art. 5(1)(b)); a new purpose for existing data is a new design decision (back to the threat model, re-consent if the lawful basis requires it).
6. **Don't store what you can derive; don't keep raw what you can reduce.** Prefer a hash/token over the raw value, a coarse bucket over the precise one, a boolean flag over the document that proved it. Every reduction shrinks both the breach blast radius and the DSR surface.
7. **No PII in the wrong places:** never in URLs, logs, analytics, error messages, or third-party telemetry — identify subjects by opaque ID everywhere downstream (`07-operations/observability.md` rule 5, `_spines/security-privacy.md` rules 7). This is enforced design, not etiquette: it's what makes erasure tractable later.

## Retention scheduling

8. **Every PII field/table has a declared retention period** tied to its purpose — kept in a retention register (a `docs/retention.md` table: field/table → class → purpose → max age → disposition). Indefinite retention is a decision someone signs, not the default (Art. 5(1)(e)).
9. **Retention is enforced by a scheduled job, not by hope** — an automated sweep deletes or anonymizes records past their max age. A retention period with no expiry mechanism is fiction.
10. **Retention and the soft-delete decision are one design choice.** A table that needs erasure must have a real hard-delete path or an anonymize-in-place path; if it uses soft delete (`deleted_at`), record whether `deleted_at` triggers eventual hard purge or anonymization (`03-design/data-modeling.md` rule 8). A soft-delete-only table can never satisfy erasure — that is a design bug to catch at modeling time.
11. **Retention rides the backup ladder.** Erasure of live data is not complete until the record ages off backups; the deletion SLA must accommodate the backup retention ladder (7 daily / 4 weekly / 12 monthly — `07-operations/backup-dr.md` rule 4). Document this lag in the DSR response; don't restore a purged subject from an old backup without re-applying the erasure.

## Data-subject-rights (DSR) fulfillment

12. **The four rights must be technically satisfiable by design,** not improvised under deadline (GDPR Arts. 15–17, 20):
    - **Access / Export** (Art. 15, 20): assemble all of a subject's data, keyed by their identifier, into a structured, machine-readable export (JSON/CSV). If "all their data" can't be enumerated from the schema's PII map, the model is wrong.
    - **Rectification** (Art. 16): the normal edit path already corrects most fields; for derived/cached copies, the correction must propagate.
    - **Erasure** (Art. 17): the hard-delete/anonymize path from rule 10, applied across primary store, derived stores, caches, search indexes, and (on a lag) backups.
13. **A DSR is a verified, logged, deadlined workflow:**
    1. **Authenticate** the requester is the data subject (or authorized agent) — DSR endpoints are a prime account-takeover and enumeration target; never disclose on an unverified request.
    2. **Locate** every store holding the subject's data via the PII map (rule 1) — primary DB, derived tables, caches, analytics, third-party processors.
    3. **Act** (export / correct / erase), including downstream and processor propagation.
    4. **Respond** within **one month** of receipt; extendable by two months for complex/numerous requests if the subject is told within the first month (Art. 12(3)).
    5. **Log** the request, identity check, scope, action, and completion in the ops/audit log — without copying the exported PII into that log.
14. **Erasure has lawful exceptions** (legal-hold, tax/accounting records, active contract, fraud defense — Art. 17(3)). Encode them: an exempt record is retained with a recorded reason and its own expiry, not silently kept and not silently deleted.
15. **DSR mechanics are tested.** At least one automated test proves the export assembles a subject's full record and the erasure path removes it from every live store — the same test that proves the model satisfies rules 10 and 12.

## Standards basis

- **GDPR Art. 5 — processing principles** (gdpr-info.eu/art-5-gdpr): purpose limitation (5(1)(b)), **data minimization** (5(1)(c) — "adequate, relevant and limited to what is necessary"), **storage limitation** (5(1)(e) — kept identifiable "no longer than is necessary"), integrity/confidentiality (5(1)(f)). Direct basis for rules 4–9. Accountability (5(2)) is why classification and the retention register are written down, not tacit.
- **GDPR Arts. 15–17, 20 — data-subject rights:** Art. 15 right of access, Art. 16 rectification, Art. 17 erasure ("right to be forgotten", with the 17(3) exceptions), Art. 20 portability ("structured, commonly used and machine-readable format", limited to subject-provided data). Basis for rules 12–14. **Art. 12(3)** sets the one-month (+2) response window of rule 13.4. **Art. 25 — data protection by design and by default** is why all of this is a design-time standard, not a launch checklist.
- **Privacy by Design — 7 foundational principles** (Ann Cavoukian, gpsbydesigncentre.com/the-seven-foundational-principles): (1) proactive not reactive, (2) **privacy as the default**, (3) **embedded into design/architecture** — not bolted on, (4) full functionality / positive-sum, (5) end-to-end lifecycle protection, (6) transparency, (7) respect for the user. Rules 1–3 (classify-at-design) and 10–12 (DSR satisfiable by construction) operationalize principles 2, 3, and 5; codified into law as GDPR Art. 25.
- **NIST Privacy Framework v1.0** (nist.gov/privacy-framework) — functions Identify-P / Govern-P / Control-P / Communicate-P / Protect-P. Category **CT.DM (Data Processing Management)** drives the retention register + scheduled-deletion mechanism (rules 8–9); **CT.PO/Control-P** drives DSR enablement (rules 12–13); **ID.IM (Inventory & Mapping)** drives the field-level PII map (rule 1). (v1.1 is in Initial Public Draft — comment period closed June 2025, final "coming 2026" — adding a standalone Govern-P function and an AI-and-privacy section; **v1.0 remains the current published version.**)
- **OECD Privacy Guidelines (Collection Limitation, Purpose Specification, Use Limitation)** and **ISO/IEC 29100 / ISO/IEC 27701** (privacy information management) corroborate the same minimize/purpose-bind/retain-then-dispose lifecycle as a vendor-neutral baseline.
- Ties into the security spine's PII baseline (`_spines/security-privacy.md` rules 5–9): that doc owns encryption-in-transit/at-rest, opaque-ID logging, and breach notification (GDPR Arts. 33/34); this doc owns the design-time data-governance and DSR procedures it points at.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every PII/payment field has a recorded class, a named purpose, and a retention entry; erasure and export paths exist and are tested for it (no soft-delete-only PII table); DSR requests are authenticated, scoped via the PII map, and answered within one month.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the threat-model template it injects carries the data-classification field this doc builds on).
