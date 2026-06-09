# Refactoring Discipline

A refactor is a behavior-preserving change to the *shape* of code — and that one constraint governs everything below. This doc draws the lines refactoring shares a border with: a feature/fix changes behavior, debt-paydown (`08-maintenance/tech-debt-policy.md`) settles a logged shortcut, speculative abstraction builds for an imagined future (forbidden by `04-build/coding-standards.md` rule 4). Refactoring is none of those: it improves code you are touching *now*, under the protection of tests that prove behavior didn't move. Get the definition wrong and a "refactor" smuggles in a behavior change with no test to catch it — the single most expensive mistake in this discipline.

## What a refactor is

1. **A refactor preserves observable behavior.** Same inputs produce the same outputs, the same side effects, the same errors. If any caller, response, persisted value, or emitted event would differ, it is not a refactor — it is a feature or a fix, and it is specified, reviewed, and tested as one. "Refactor" is never a label that exempts a change from the behavior-change rules.
2. **A refactor rides existing test coverage.** The tests that pass before the change pass *unchanged* after it — that green-to-green transition is the proof the behavior held. A change that requires editing test *expectations* (not just test internals) has changed behavior by definition and has left the refactoring regime (see rule 6).
3. **Refactor and the change it enables are two steps, in order.** When a feature is hard to add because of the current shape, first refactor to make the addition easy, then make the easy addition — never braid the two into one indivisible diff where the behavior-changing lines hide among the shape-changing ones.

## Scoping a refactor against a PR

4. **An internal-only refactor may ride the feature change it serves.** If the reshaping touches no public surface and forces no test-expectation edits, keeping it in the same PR as the feature it enables is correct — the refactor's reason to exist is visible right beside it, and a reviewer reads one coherent story.
5. **A refactor that touches the public API surface gets its own PR.** When the change alters an exported signature, a route or schema, a published contract, a config key, or any boundary other code depends on (`03-design/api-contract-design.md`), it is isolated into a standalone diff — even when behavior is preserved — so the blast radius is reviewable on its own and revertible without dragging unrelated feature work back with it.
6. **A change that rewrites test expectations gets its own PR.** Editing what a test *asserts* (versus refactoring the test's setup) signals the contract under test moved; that diff is separated so reviewers see the expectation change naked, not buried under reshaping. If the expectation edit is the *point* of the change, it was a behavior change wearing a refactor's name (rule 1) and is specified accordingly.
7. **Keep a refactor diff revertible as a unit.** Each refactor PR is one mechanical transformation (rename, extract, inline, move, introduce parameter) carried all the way through, not a grab-bag of unrelated cleanups — so `git revert` of that one commit undoes exactly one decision and nothing else.

## The Boy-Scout boundary

8. **Leave the code you touched cleaner than you found it — bounded to what you touched.** Opportunistic cleanup of the module already in the diff is encouraged; expanding the diff into adjacent files or unrelated cleanups for their own sake is not. The boundary is the change's natural footprint, not the whole codebase.
9. **When cleanup would balloon the diff, stop and split it out.** If improving the shape would grow the change past what a reviewer can hold in one sitting, the cleanup becomes its own PR (rules 5–7) rather than swelling the current one. A large reshaping is a planned, isolated change, never a drive-by.
10. **A discovered larger reshaping is logged, not crammed in.** Spotting a structural problem beyond the current footprint produces a debt-log entry with a paydown trigger (`08-maintenance/tech-debt-policy.md`), not an in-the-moment rewrite that triples the diff and hides the original change.

## Refactor vs its neighbors

11. **Refactor is not debt-paydown.** Debt-paydown settles a *logged* shortcut against its recorded trigger (`08-maintenance/tech-debt-policy.md`); refactoring improves the shape of code you are already in, whether or not a debt row named it. Paying down a logged debt may *be* done by refactoring, but the trigger and the log entry are the debt mechanism — refactoring is the act, not the accounting.
12. **Refactor is not speculative abstraction.** It improves the shape of code being touched *now* for a present reason; it never adds layers, parameters, or generality for a future that hasn't arrived. "Extract an interface in case we swap providers later" is the speculative generality `04-build/coding-standards.md` rule 4 forbids — not a refactor. Refactor toward the change you are actually making, not the one you imagine.

## When not to refactor

13. **No test coverage over the code? Add tests first.** A refactor without a covering test is an unverifiable claim that behavior was preserved. When the target lacks tests (`04-build/testing-strategy.md`), the characterization tests that pin current behavior come first — as their own commit or PR — and only then does the reshaping proceed against that green baseline.
14. **Don't refactor under a release freeze or on the critical path of an incident.** Behavior-preserving is a goal, not a guarantee; reshaping carries non-zero risk and belongs outside the windows where risk is least acceptable. Fix the incident with the smallest change; reshape afterward.
15. **Don't refactor code you aren't otherwise touching just to refactor it.** A standalone reshaping needs a present reason — it enables imminent work, pays a triggered debt, or removes an active hazard. A reshaping whose only justification is taste is deferred to the debt log (rule 10), where it competes for the standing paydown budget like any other improvement.

## Standards basis

- **Martin Fowler, *Refactoring: Improving the Design of Existing Code* (2nd ed., 2018)** (refactoring.com) — the definition that grounds this whole doc: refactoring is "a change made to the internal structure of software to make it easier to understand and cheaper to modify *without changing its observable behavior*" (rule 1). Fowler's discipline of small behavior-preserving steps under a passing test suite is rules 2–3 and 7; his catalog entries (Extract Function, Inline, Rename, Move, Introduce Parameter) are the "one mechanical transformation per diff" of rule 7. Fowler's distinction between refactoring and "adding function" is the feature-vs-refactor line of rules 1 and 6.
- **Kent Beck — "for each desired change, make the change easy (warning: this may be hard), then make the easy change"** (Beck, on X/Twitter, 2012; widely cited as the *two hats* preface to Fowler's *Refactoring*, where the refactoring hat and the feature hat are never worn at once) — the direct basis for rule 3 (refactor-then-change, in order, never braided) and rule 12 (refactor toward the change you are actually making).
- **Parallel Change / Expand–Contract** (Danilo Sato, martinfowler.com/bliki/ParallelChange.html) — the three-phase expand → migrate → contract pattern for evolving a contract without a breaking flag-day; the reason a public-surface change is isolated into its own reviewable, revertible diff (rule 5) rather than mixed with feature work — each phase is independently shippable.
- **The Boy Scout Rule** (Robert C. Martin, *Clean Code*, 2008; orig. Baden-Powell, "leave the campground cleaner than you found it") — leave each module marginally cleaner than found, bounded to what you touched; the basis for rules 8–10. The same principle anchors `08-maintenance/tech-debt-policy.md` (interleave-on-touch), and the boundary here is its diff-discipline corollary: clean what you touched, log the rest.
- **Characterization Tests** (Michael Feathers, *Working Effectively with Legacy Code*, 2004) — tests that pin the *current* behavior of code lacking coverage so a reshaping has a baseline to preserve against; the direct basis for rule 13 (add tests before refactoring untested code). Feathers' definition of legacy code as "code without tests" is why rule 13 is a hard precondition, not advice.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: This diff labeled a refactor preserves behavior and rides unchanged passing tests; anything touching the public API surface or rewriting test expectations is in its own revertible PR; cleanup stays within the touched footprint and untested targets got characterization tests first.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only.
