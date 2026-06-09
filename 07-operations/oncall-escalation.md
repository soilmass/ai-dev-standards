# On-Call & Escalation

Who gets woken up, when, and by what. Built for the common case here: **one operator, no rotation, no backup human** — which inverts the usual SRE math. A real team can absorb a noisy pager across nine people; you cannot. With no one to escalate *to* and no one to hand off *to*, alert discipline stops being hygiene and becomes the whole game. This doc sets the paging policy, severity ladder, escalation chain, and the solo-operator adaptations of each.

## Paging policy — what is allowed to wake you

1. **A page means: a human must act now.** If no immediate human action changes the outcome, it is not a page — it is a ticket or a dashboard. Wiring a non-actionable condition to the pager is the single fastest way to destroy the channel (`07-operations/observability.md` rule 11: every alert is actionable and links a runbook).
2. **Page on symptoms users feel, never on causes.** Page on error-budget burn, elevated 5xx, p95 over threshold, a dead journey SLI, a client error spike — not on CPU, memory, or disk in isolation (those are dashboard/ticket signals that *predict* a symptom). Symptom-based paging is what keeps the alert count bounded by user-facing failure modes instead of by infrastructure noise (`07-operations/slo-error-budgets.md` rule 5: multi-window, multi-burn-rate burn alerts are the page-tier shape).
3. **Every page links a runbook.** A page that arrives without a `07-operations/incident-runbook.template.md` entry behind it is a page you cannot action at 3 a.m. — write the runbook before the alert ships, or don't ship the alert.
4. **Target ~1:1 alert-to-incident ratio.** If an alert fires more often than it corresponds to a real incident, it is mistuned: raise its threshold, add a confirmation window, or delete it. The SRE rule of thumb — **no more than ~2 paging events per 12-hour window** before fatigue sets in — is a hard ceiling for a solo operator with no relief; cross it and you stop reacting with urgency, which means the *real* page gets the same dulled response as the noise.

## Severity levels

5. One ladder, used everywhere (alerts, runbooks, postmortems) so a severity word means the same thing in every artifact. Severity is set by **user impact**, not by how interesting the cause is.

| Sev | Meaning | Response | Example |
|---|---|---|---|
| **S1** | Users blocked — core journey down, data at risk | **Page now.** Drop everything; mitigate first, diagnose later. | Login fails for everyone; checkout 500s; data-loss in progress |
| **S2** | Degraded — works but materially worse | Page only in business hours; ticket otherwise. | p95 doubled; one non-core feature down; elevated but non-fatal error rate |
| **S3** | Annoyance — cosmetic or single-user | Ticket. Never pages. | One broken image; a rare edge-case error |

6. **Mitigate before you diagnose** on S1. The job during an incident is to stop user pain — roll back (`06-delivery/rollback.md`), flip a kill switch, or enter maintenance mode — *then* find root cause. Curiosity-driven debugging while users are down is the classic failure (the "unauthorized hero fix" that deepens the outage in SRE's worked example).
7. **Severity can be promoted mid-incident** as impact becomes clear; it is a running judgment, not a one-time label. Record the final severity in the postmortem for error-budget accounting (`07-operations/slo-error-budgets.md`).

## Escalation chain

8. **Declare an incident** (not "I'll just look into it") the moment any of these is true — the SRE trip-wires:
   - the issue is user-visible, **or**
   - it is unresolved after **~1 hour** of focused effort, **or**
   - it needs help you don't have (a second pair of hands, a vendor, a decision above your pay grade).
   Declaring early is cheap; declaring late is how a 10-minute blip becomes a 4-hour outage.
9. **Define the chain before the incident, written in the runbook**, even when most links are not human. For a solo operator the realistic chain is:
   1. **You** — mitigate per the runbook.
   2. **The platform/host provider's support or status page** — the closest thing to "escalate to backup." Know *how* to open a priority ticket and *where* the status page is **now**, not while it's down.
   3. **The upstream vendor** whose dependency is failing (auth provider, payments, DB host).
   4. **The deliberate fallback: maintenance mode / static degraded page.** When no human and no vendor can fix it fast, taking the system to a clean degraded state is a legitimate terminal escalation, not a defeat (`07-operations/backup-dr.md`).
10. **The escalation line in each runbook is the explicit "stop solo-debugging" trip-wire** (`07-operations/incident-runbook.template.md` Mitigation → Escalation). Pre-deciding *when to stop* removes the in-the-moment judgment call that exhaustion and tunnel-vision reliably get wrong.

## Incident command — even as a team of one

11. SRE separates three roles — **Incident Commander** (holds state, decides), **Operations Lead** (applies the fixes), **Communications Lead** (updates stakeholders/users). Solo, you hold all three, but keep them as *modes you switch between*, not a blur: decide → act → communicate, in turn. Conflating "command" with "ops" is what produces unannounced changes that nobody is tracking.
12. **Keep a live incident state document** — even a scratch file — with the timeline and current hypothesis at the top, updated as you go. It is the memory you won't have post-adrenaline, and it becomes the spine of the postmortem.
13. **Communicate to users on S1** as a first-class task, not an afterthought: a status note ("we're aware, investigating") buys patience and is the Communications-Lead role made concrete. Decide the channel (status page / banner) before you need it.

## Alert quality & fatigue (the part that matters most solo)

14. **Treat the alert set as a maintained artifact, with a budget.** Each new page must justify its existence against rule 4's ceiling. An alert that is routinely ignored, snoozed, or "known noise" is not benign — it raises the noise floor for every real page and **gets retuned or deleted**, never tolerated (`07-operations/observability.md` rule 11).
15. **Review fired alerts on a cadence** (monthly, or at each release glance per `06-delivery/release-process.md`): for each page that fired, ask "did a human have to act?" No → fix the alert, not just the symptom. This is the only feedback loop that keeps a solo pager survivable over years.
16. **No relief means tighter tuning, not looser.** A team can carry a marginal alert because the cost is spread; you carry 100% of every false page at every hour. Prefer **multi-window burn-rate confirmation** (`07-operations/slo-error-budgets.md` rule 5) and confirmation delays over raw thresholds precisely because flapping has no one else to absorb it.

## Blameless culture (yes, with yourself)

17. Every S1/S2 gets a **blameless postmortem within 48h** (`07-operations/incident-runbook.template.md` Postmortem). Blameless applies even when you are the only suspect: name the systemic gap — the missing guard, the absent alert, the runbook that didn't exist — never "I was careless." "Be more careful" is not a follow-up; a tracked preventive change is.
18. **Repeated pages from one cause escalate out of the pager and into design** — a fix, a guard, or an ADR (`07-operations/slo-error-budgets.md` rule 8, `00-governance/standards-lifecycle.md` feedback loop). The pager is for novel failure; recurring failure is a backlog item, not a lifestyle.

## Standards basis
- **Google SRE — *Being On-Call*** (*SRE* book ch.11, https://sre.google/sre-book/being-on-call/): a page must be actionable; signal-to-noise must stay high or fatigue dulls response to genuine emergencies; "one can only react with a sense of urgency a few times a day"; sustainable shifts are capped at 12 hours. Grounds the paging policy (rules 1–4) and the fatigue-budget framing in rules 14–16 — the ~2-pages-per-12h ceiling is SRE's, applied as a *hard* limit here because a solo operator has no relief to spread load across.
- **Google SRE Workbook — *On-Call*** (https://sre.google/workbook/on-call/): P1 pages the on-call (immediately actionable, SLO-impacting) / P2 emails / P3 informational — the severity-to-channel mapping behind rule 5's S1/S2/S3 ladder; the ~2 incidents per 12-hour shift target (rule 4); explicit escalation-to-backup paths as the basis of psychological safety (rule 9); and that 24/7 coverage needs ~8 people single-site — the staffing reality that makes the no-rotation solo adaptations in this doc necessary rather than optional.
- **Google SRE — *Managing Incidents*** (https://sre.google/sre-book/managing-incidents/): the Incident Commander / Operations Lead / Communications Lead role separation drawn from the Incident Command System (ICS), the "recursive separation of responsibilities," the live incident-state document, and the declare-an-incident trip-wires (second team needed, customer-visible, or unsolved after ~1 hour). Grounds the escalation trip-wires (rule 8), the roles-as-modes adaptation (rule 11), the state document (rule 12), and "mitigate before diagnose" (rule 6, contra the unauthorized-hero-fix anti-pattern).
- **Google SRE — *Blameless Postmortem Culture*** (https://sre.google/sre-book/postmortem-culture/): postmortems find contributing causes without indicting a person and convert findings into tracked action; root cause ≠ trigger. Grounds rule 17's self-blameless framing and the 48-hour cadence shared with `07-operations/incident-runbook.template.md`.
- **Error-budget-driven alerting** (*SRE Workbook* "Alerting on SLOs", https://sre.google/workbook/alerting-on-slos/): multi-window, multi-burn-rate burn alerts are the page-tier signal; rules 2 and 16 page on burn rather than on resource causes, cross-referencing `07-operations/slo-error-budgets.md` rule 5.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: If this change adds or alters an alert, confirm the alert is symptom-based, actionable, and links a runbook with a defined escalation step; if it removes a failure mode, retire the now-dead alert in the same PR.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the per-scenario `docs/incident-runbook.template.md` injected by `07-operations/incident-runbook.template.md` carries the Severity and Escalation lines this doc defines).
