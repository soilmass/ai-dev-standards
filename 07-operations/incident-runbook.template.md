# Incident Runbook: <FAILURE_SCENARIO_NAME>

> One runbook per failure scenario you can foresee (DB unreachable, auth provider down, deploy broke production, error-budget burn alert). Fill the top half *before* any incident; the bottom half is filled during/after one. Keep steps copy-pasteable — 3 a.m. you has no judgment to spare.
>
> Backtick layer paths in this file (e.g. `06-delivery/rollback.md`) are relative to the standards library root, not to this `docs/` folder. The library's absolute location is the path stamped into this project's `CLAUDE.md` (its standards-path); open the doc there.

- **Scenario:** <WHAT_IS_FAILING_FROM_THE_USERS_PERSPECTIVE>
- **Severity when it fires:** <S1_USERS_BLOCKED | S2_DEGRADED | S3_ANNOYANCE>
- **Owning alert(s):** <ALERT_NAME_OR_DASHBOARD_LINK>

## Detection

- **Symptoms:** <WHAT_THE_ALERT_OR_USER_REPORT_LOOKS_LIKE>
- **Confirm with:** <EXACT_DASHBOARD_QUERY_OR_COMMAND_TO_VERIFY_ITS_REAL>
- **Not this, but similar:** <NEARBY_FAILURE_MODES_AND_HOW_TO_TELL_THEM_APART>

## Triage

1. <FIRST_CHECK — usually: recent deploy? `git log` / deploy dashboard>
2. <SECOND_CHECK — usually: external dependency status page>
3. <DECISION_POINT: which mitigation below applies>

## Mitigation

| If | Then |
|---|---|
| <CAUSE_A_E_G_BAD_DEPLOY> | <ACTION — e.g. rollback path 2 per `06-delivery/rollback.md`, exact commands/clicks> |
| <CAUSE_B_E_G_PROVIDER_DOWN> | <ACTION — e.g. flip kill switch X, post status note> |
| <CAUSE_C> | <ACTION> |

- **Escalation:** <WHEN_TO_STOP_SOLO_DEBUGGING_AND_CALL_THE_HOST_PROVIDER_OR_GO_TO_MAINTENANCE_MODE>

## Postmortem (fill within 48h of resolution)

> Write it **blameless**: assume everyone acted reasonably on the information they had. Name the systemic gaps (missing guard, missing alert, unclear runbook), never the person. The goal is a more reliable system, not a culprit.

- **Timeline:** <DETECTED_AT / MITIGATED_AT / RESOLVED_AT>
- **Impact:** <USERS_AFFECTED_DURATION_DATA_LOSS_IF_ANY>
- **Root cause:** <THE_ACTUAL_CAUSE_NOT_THE_TRIGGER>
- **Error budget consumed:** <PER_SLO_ACCOUNTING_SEE_SLO_DOC>
- **Follow-ups:** <CONCRETE_PREVENTIONS — each becomes a tracked task; "be more careful" is not a follow-up>
- **Runbook gaps:** <WHAT_THIS_RUNBOOK_GOT_WRONG_OR_MISSED — fix it now, same PR>

## Standards basis
- **Google SRE — Incident Management** (https://sre.google/sre-book/managing-incidents/; *Managing Incidents*): the "three Cs" — coordinate, communicate, control — and clear roles (Incident Commander, Communications Lead, Operations Lead) drawn from the Incident Command System (ICS). On a solo project one person holds all three; this template's Detection → Triage → Mitigation → Escalation structure encodes the same control flow, and the Escalation line is the explicit hand-off point that prevents lone-debugging spirals.
- **Google SRE — Blameless Postmortem Culture** (https://sre.google/sre-book/postmortem-culture/): postmortems must find contributing causes without indicting anyone; the standard distinguishes root cause from trigger and converts findings into tracked preventive action. Grounds the Postmortem section's blameless framing, "root cause not trigger", and the "'be more careful' is not a follow-up" rule.
- **48-hour postmortem cadence**: writing the postmortem while the incident is fresh is SRE-recommended practice; this template fixes it at 48h of resolution.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this change alters detection, mitigation, or recovery behavior, update the affected incident runbook in the same PR.

## Bootstrap
- What new-project.sh injects for this standard: this template into `docs/incident-runbook.template.md` — copied per foreseeable failure scenario.
