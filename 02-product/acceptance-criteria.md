# Acceptance Criteria

How to write criteria that can be checked, not argued about. Criteria are the contract between the spec and the tests: if a criterion can't become a test or a named manual check, it isn't a criterion yet.

## The form

Default to **Given / When / Then**:

> Given <a precondition the system can be put into>, when <a single action occurs>, then <an observable result holds>.

Equivalent checkable forms are fine (invariant statements, example tables) as long as each criterion keeps the three properties below.

## The three properties

1. **Observable.** The result is something a test or a person can see: a response, a rendered state, a stored record, an emitted event. "The code is clean" or "auth is handled properly" are not criteria.
2. **Deterministic.** Two people (or one agent twice) reach the same pass/fail verdict. Quantify anything vague: "fast" → a budget; "handles bad input" → which inputs, which behavior.
3. **Atomic.** One criterion, one assertion. Compound criteria ("X and Y unless Z") hide partial failures — split them.

## Rules

- Every spec scope bullet has at least one criterion; every criterion traces back to a scope bullet. Orphans on either side mean the spec is out of date.
- Cover the unhappy paths explicitly: invalid input, unauthorized access, empty states, failure of an external dependency. Most production bugs live where criteria were only written for success.
- Criteria for non-functional requirements point at the standing gates rather than restating them (e.g. "meets the performance budgets" — `05-verification/a11y-perf-gates.md`).
- Each criterion maps to at least one automated test, or — where automation is genuinely impossible — a named manual verification step recorded in the PR.
- Write criteria **before** implementation. Criteria written after the code passes describe the code, not the requirement.

## Worked example

> **Scope bullet:** users can reset a forgotten password.
>
> 1. Given a registered email, when a reset is requested, then a single-use, time-limited reset link is sent to that email.
> 2. Given an unregistered email, when a reset is requested, then the response is identical to the registered case (no account enumeration).
> 3. Given an expired or already-used reset link, when it is opened, then the reset is refused with a path to request a new link.

## Standards basis

- **Given/When/Then (Dan North, Liz Keogh, Chris Matts; formalized as Gherkin by Cucumber)** — one precondition, one action, one observable outcome per scenario; the canonical structure behind "The form." See [Cucumber: Gherkin reference](https://cucumber.io/docs/gherkin/).
- **Specification by Example (Gojko Adzic)** — concrete examples are the shared acceptance contract and the source of automated checks; underpins the "maps to at least one automated test" rule and the example-table alternative to GWT. See [gojko.net: SBE 10 years later](https://gojko.net/2020/03/17/sbe-10-years.html).
- **INVEST — "T" for Testable (Bill Wake, 2003)** — a story without checkable criteria is unfinished; this doc operationalizes Testable via the Observable/Deterministic/Atomic properties. See [Agile Alliance: INVEST](https://agilealliance.org/glossary/invest/).
- **Scrum Guide 2020 — Definition of Done as a commitment** — criteria are the per-item slice of the Increment's quality commitment; non-functional criteria defer to the standing gates (Done is teamwide, not restated per story). See [scrumguides.org](https://scrumguides.org/scrum-guide.html).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every acceptance criterion for this task maps to at least one automated test or a named manual verification step.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the spec template's acceptance-criteria section points here).
