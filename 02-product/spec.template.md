# Spec: <FEATURE_OR_CHANGE_NAME>

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

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Confirm the diff stays within the approved spec's scope and non-goals; name any scope creep explicitly and split it out.

## Bootstrap
- What new-project.sh injects for this standard: this template into `docs/spec.template.md` — copied per feature, filled in before implementation starts.
