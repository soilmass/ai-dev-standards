# Threat Model: <FEATURE_NAME>

> Per-feature, not global: copy this file when building anything that touches auth, sessions, money, PII, file handling, or new input surfaces. Keep it short — a filled-in page beats an abandoned framework. Cross-layer security rules: `_spines/security-privacy.md`.

- **Date:** <YYYY-MM-DD>
- **Feature/spec:** <LINK_TO_SPEC>
- **Data classification touched:** <PUBLIC | INTERNAL | PII | CREDENTIALS_OR_PAYMENT>

## Assets

What this feature creates, reads, or moves that an attacker would want.

| Asset | Where it lives | Worst-case impact if compromised |
|---|---|---|
| <ASSET_E_G_SESSION_TOKENS> | <STORE_OR_TRANSIT> | <IMPACT> |

## Entry points

Every way input reaches this feature.

| Entry point | Authn/authz required? | Input validated by |
|---|---|---|
| <ROUTE_ACTION_WEBHOOK_OR_UPLOAD> | <YES_HOW | NO_WHY_SAFE> | <SCHEMA_OR_MECHANISM> |

## Threats

Walk STRIDE as a prompt — spoofing, tampering, repudiation, information disclosure, denial of service, elevation of privilege — and keep the ones that are real here.

Rate each threat L/M/H on both axes using this rubric (rate, don't agonize — the point is to sort, not to be precise):

- **Likelihood** — H: reachable by untargeted scanning or anonymous users. M: requires an authenticated user or specific knowledge. L: requires insider access or chaining several exploits.
- **Impact** — H: account takeover or compromise of a whole data class. M: single-user data exposure or integrity loss. L: nuisance or degradation.

| # | Threat | Likelihood (L/M/H) | Impact (L/M/H) |
|---|---|---|---|
| T1 | <WHO_DOES_WHAT_TO_WHAT> | <L_M_H> | <L_M_H> |
| T2 | <WHO_DOES_WHAT_TO_WHAT> | <L_M_H> | <L_M_H> |

## Mitigations

Every threat above gets a row: a mitigation implemented in this change, or an explicit acceptance with reason.

| Threat | Mitigation (or accepted risk + reason) | Where implemented / verified |
|---|---|---|
| T1 | <MITIGATION> | <FILE_TEST_OR_GATE> |
| T2 | <MITIGATION> | <FILE_TEST_OR_GATE> |

## Review trigger

Re-open this model when: <CONDITIONS_E_G_NEW_ENTRY_POINT_NEW_DATA_CLASS_AUTH_CHANGE>.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: For changes touching auth, session, input parsing, file handling, or data access: confirm the feature's threat model exists and each listed mitigation is implemented in this diff.

## Bootstrap
- What new-project.sh injects for this standard: this template into `docs/threat-model.template.md` — copied per qualifying feature.
