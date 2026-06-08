# Spec: <FEATURE_OR_CHANGE_NAME>

> Backtick layer paths in this file (e.g. `02-product/acceptance-criteria.md`, `02-product/task-decomposition.md`) are relative to the standards library root, not to this `docs/` folder. The library's absolute location is the path stamped into this project's `CLAUDE.md` (its standards-path); open the docs there.

- **Date:** <YYYY-MM-DD>
- **Status:** <Draft | Approved | Implemented>
- **Owner:** <WHO_DECIDES_SCOPE_QUESTIONS>

## Problem

<WHAT_HURTS_AND_FOR_WHOM. State the user/business problem, not the solution. 2–5 sentences with evidence where it exists.>

## Scope

<WHAT_THIS_CHANGE_DELIVERS. Bullet the observable capabilities; each should be traceable to acceptance criteria below.>

- <CAPABILITY_1>
- <CAPABILITY_2>

## Non-goals

<WHAT_THIS_EXPLICITLY_DOES_NOT_DO — adjacent work that someone might assume is included. Cutting scope here is what keeps the PRs small.>

- <NON_GOAL_1>

## Acceptance criteria

<TESTABLE_CRITERIA per `02-product/acceptance-criteria.md` — Given/When/Then or equivalently checkable statements. Every criterion maps to a test or named manual check.>

1. Given <PRECONDITION>, when <ACTION>, then <OBSERVABLE_RESULT>.
2. Given <PRECONDITION>, when <ACTION>, then <OBSERVABLE_RESULT>.

## Constraints

<HARD_LIMITS the implementation must respect: performance budgets, compatibility, data rules, deadlines, security/threat-model requirements. "None beyond the standards" is a valid entry.>

## Decomposition note

<HOW_THIS_SPLITS_INTO_PRS per `02-product/task-decomposition.md` — list the planned shippable units, or state it fits one PR.>

## Standards basis

- **INVEST (Bill Wake, 2003)** — Problem/Scope/Non-goals/Acceptance criteria force a Valuable, Negotiable, Small, Testable unit; Non-goals are how Small is kept. See [Agile Alliance: INVEST](https://agilealliance.org/glossary/invest/).
- **Specification by Example (Gojko Adzic) + Given/When/Then (North/Keogh/Matts, Gherkin)** — the Acceptance criteria section captures shared, example-driven, executable-shaped criteria. See [gojko.net](https://gojko.net/2020/03/17/sbe-10-years.html), [Cucumber: Gherkin](https://cucumber.io/docs/gherkin/).
- **User-story mapping (Jeff Patton)** — Scope as user-visible capabilities and the Decomposition note as thin vertical slices. See [jpattonassociates.com](https://jpattonassociates.com/the-new-backlog/).
- **Working in small batches (DORA / Accelerate)** — the Decomposition note plans shippable units, not a big-batch drop. See [dora.dev](https://dora.dev/capabilities/working-in-small-batches/).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Confirm the diff stays within the approved spec's scope and non-goals; name any scope creep explicitly and split it out.

## Bootstrap
- What new-project.sh injects for this standard: this template into `docs/spec.template.md` — copied per feature, filled in before implementation starts.
