# Threat Modeling

The *how* of threat modeling: the procedure a designer runs at design time to find what can go wrong before code exists. The per-feature output is the filled-in `03-design/threat-model.template.md`; this doc is the method that produces it. Cross-layer security rules it feeds: `_spines/security-privacy.md`.

Threat modeling is a design activity, not an audit. Run it while the design is still cheap to change — the value is steering the architecture, not documenting it after the fact.

## When to (re)model — trigger conditions

Threat-model a change when **any** of these is true; skip (and say so) when none are.

1. The change touches a **trust boundary** or **sensitive asset**: auth, sessions, money, secrets/credentials, PII, file handling, or a new externally-reachable input surface.
2. A **new entry point** appears: a route, action, webhook, queue consumer, upload, or third-party integration.
3. A **data class** is added or its classification rises (e.g. INTERNAL → PII; see `03-design/data-modeling.md`).
4. **Authn/authz logic changes**: new role, new permission check, changed session lifetime, federation.
5. **Architecture shifts**: a new external dependency, a new data store, a component crossing a network or tenant boundary (`03-design/architecture-standards.md`).
6. **Periodic**: re-walk the model for a security-relevant feature at least once per major release, and after any security incident in its area.

A change failing all six does not need a model. Record *that* decision in the PR — "no threat model: no trust boundary, asset, or entry-point change" — so the skip is reviewable, not silent.

## The Four-Question Framework

Every model answers four questions in order (Shostack; the Threat Modeling Manifesto framing the OWASP cheat sheet adopts). The template's sections map one-to-one — fill them as you answer.

1. **What are we working on?** → Assets + Entry points (system model).
2. **What can go wrong?** → Threats (STRIDE-driven; attack trees where needed).
3. **What are we going to do about it?** → Mitigations (one response per threat).
4. **Did we do a good enough job?** → Review trigger + coverage check.

Do them in order. Skipping Q1 is the most common failure — you cannot enumerate threats against a system you haven't decomposed.

## Step 1 — Model the system (Q1)

1. **Decompose into a data-flow view.** Identify external entities, processes, data stores, and the data flows between them. The boundaries between differently-trusted elements are **trust boundaries** — every flow crossing one is a place a threat lives.
2. **List assets** (template: Assets table). What does this feature create, read, or move that an attacker wants? Tie each asset to its data classification (`03-design/data-modeling.md`).
3. **List entry points** (template: Entry points table). Every way input reaches the feature, each tagged with its authn/authz requirement and how its input is validated (`03-design/api-contract-design.md` rule 3 — parse at the boundary).
4. Scope it to *this change*. A whole-system model is a deliverable; a per-feature model is a half-page. Build the half-page.

## Step 2 — Find what can go wrong (Q2)

5. **Walk STRIDE per element.** For each entry point and trust-boundary crossing, prompt with the six categories and keep the threats that are real here:

   | Category | Property violated | Ask |
   |---|---|---|
   | **S**poofing | Authentication | Can someone pretend to be another principal or component? |
   | **T**ampering | Integrity | Can data in transit or at rest be altered? |
   | **R**epudiation | Non-repudiation | Can an actor deny an action with no audit trail? |
   | **I**nformation disclosure | Confidentiality | Can data leak to someone unauthorized? |
   | **D**enial of service | Availability | Can the feature be exhausted or made unavailable? |
   | **E**levation of privilege | Authorization | Can a principal gain rights they shouldn't have? |

6. **Use attack trees to deepen a high-value threat** (Schneier). When one STRIDE finding is too coarse to mitigate as a single row, set the attacker goal as the root and decompose into sub-goals and leaf actions (AND/OR nodes). Mitigate the cheapest cut that breaks every path to the root. Don't attack-tree everything — reserve it for the one or two threats whose impact justifies the depth.
7. **Don't pad.** A threat you would not act on does not belong in the model. The deliverable is the threats that change a decision.

## Step 3 — Decide what to do (Q3)

8. **Every threat gets exactly one response** (OWASP / Shostack response set):
   - **Mitigate** — reduce likelihood or impact with a control. The default; name where it's implemented and verified.
   - **Eliminate** — remove the feature/component causing it. The strongest response; prefer it when the capability isn't essential.
   - **Transfer** — shift responsibility to another party (a provider, the customer) by contract or design.
   - **Accept** — knowingly take the risk, with a stated reason and an owner. Acceptance is legitimate; *silent* acceptance is not.
9. Record each response in the template's Mitigations table with **where it's implemented or verified** (file, test, or gate). A mitigation with no verification location is a wish, not a control.
10. Prefer eliminate/mitigate over transfer/accept for anything rated High impact.

### Rating threats to sort them

11. Rate each threat on two axes and sort by their product (OWASP Risk Rating: Risk = Likelihood × Impact). Use coarse L/M/H bands per the rubric in `03-design/threat-model.template.md` — the goal is to **order** threats for attention, not to compute false precision. OWASP's full factor model (skill/motive/opportunity/size × ease-of-discovery/exploit/awareness/detection for likelihood; technical + business impact) is the reference when a number must be defended; the L/M/H rubric is its everyday compression.
12. Mitigate High×High first; an accepted risk at High impact needs an explicit owner and sign-off.

## Step 4 — Did we do a good enough job? (Q4)

13. **Coverage check:** every entry point was walked through all six STRIDE categories; every kept threat has a response row; every response names a verification location.
14. **Set the review trigger** (template: Review trigger). Name the concrete conditions that reopen this model — they are the per-feature instance of the trigger list above (new entry point, new data class, auth change).
15. The filled model is a design artifact: it lives with the feature's spec/PR, is reviewed in the security pass of `05-verification/code-review-standard.md`, and feeds the controls in `_spines/security-privacy.md`. It is not done until the diff it describes implements its mitigations.

## Anti-patterns

- **Model-then-shelf** — producing a model that no diff implements. The model exists to change the build.
- **Boil-the-ocean** — a whole-system tome instead of a per-feature half-page; it never gets done.
- **STRIDE-as-checklist-theatre** — listing six threats per element to look thorough. Keep only real ones.
- **Rating to three decimals** — the product is for sorting; precision beyond L/M/H is wasted unless a number must be defended.
- **Audit-time modeling** — running it after implementation, when findings are expensive. It is a design step.

## Standards basis

- **Shostack's Four-Question Framework** (Adam Shostack; https://shostack.org/blog/four-question-frame/) — what are we working on / what can go wrong / what are we going to do about it / did we do a good enough job. The spine of this procedure; current and re-presented at LeanAppSec 2025.
- **Threat Modeling Manifesto** (https://www.threatmodelingmanifesto.org/) — the four-question framing the OWASP cheat sheet adopts; values-and-principles basis for "design activity, not audit" and "a working half-page beats an abandoned framework."
- **OWASP Threat Modeling Cheat Sheet** (https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html) — current master. Source for the process phases (System Modeling → Threat Identification → Response and Mitigations → Review and Validation) and the four response options (Mitigate, Eliminate, Transfer, Accept) in Step 3.
- **STRIDE** (Kohnfelder & Garg, Microsoft, 1999; formalized in the Microsoft SDL) — the six-category per-element elicitation in Step 2; each category maps to the security property it violates.
- **Attack trees** (B. Schneier, *Secrets and Lies* / "Attack Trees") — goal-decomposition with AND/OR nodes to deepen a single high-value threat (rule 6).
- **OWASP Risk Rating Methodology** (https://owasp.org/www-community/OWASP_Risk_Rating_Methodology) — Risk = Likelihood × Impact, with the threat-agent/vulnerability and technical/business factor model behind the L/M/H rubric used to sort threats (rules 11–12).
- **DFD-driven decomposition** — enumerate external entities, processes, data stores, flows, and trust boundaries before rating (Step 1), so no input surface is skipped.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: For a change touching a trust boundary, asset, or entry point (auth, sessions, money, secrets, PII, file handling, new input surface), confirm a threat model exists per `03-design/threat-modeling.md`, every kept threat has a response with a verification location, and the diff implements those mitigations.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the per-feature artifact it produces, `docs/threat-model.template.md`, is injected by that template's own Bootstrap; this doc is the method).
