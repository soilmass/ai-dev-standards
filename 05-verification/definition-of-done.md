# Definition of Done

The merge gate. A change is *done* when every line below is true — not when the code "works on my machine", and not when the agent says so. The PR template injected at bootstrap carries these as required checkboxes; CI enforces the mechanical ones.

## The checklist

A PR is mergeable when:

1. **Scoped** — it implements one concern, traceable to a spec/issue, inside that spec's scope and non-goals.
2. **Tested** — new/changed behavior has tests at the right pyramid tier (`04-build/testing-strategy.md`); the coverage gate passes.
3. **Green** — lint + format, type check, tests, secret scan, dependency audit, PR-size, migration guard, and docs check all pass in CI. No skipped required checks, no gate weakened to pass.
4. **Self-reviewed** — the author (human or agent) ran `code-review-standard.md` against the full diff; misses are fixed or justified in the PR description.
5. **Documented** — docs affected by the change are updated in the same PR (`_spines/documentation.md`), or the no-docs waiver is consciously applied.
6. **Reversible** — the rollback path is stated in the PR description (`06-delivery/rollback.md`); DB changes are forward-only migrations.
7. **Secure** — no secrets in the diff; auth/input/data-access changes checked against the feature's threat model (`03-design/threat-model.template.md`).
8. **Preview-verified** — for user-visible changes, the author looked at the preview deploy. Rendering bugs that a glance would catch don't reach review.

## What "done" is not

- Not "CI will probably pass" — CI **has** passed.
- Not "tests to be added in a follow-up" — the follow-up never comes; the budget for tests is this PR.
- Not "reviewer will catch it" — solo + AI means the checklist IS the reviewer.

## Standards basis

- **Scrum Guide 2020 — Definition of Done** (scrumguides.org): the DoD is a formal description of the state an Increment must reach to meet the product's quality measures; an item that does not meet it cannot be released or presented. This doc applies that commitment per-PR, treating the merge gate as the team's DoD made mechanical.
- **DoD as transparency artifact** (Scrum Guide 2020): the DoD gives everyone a shared understanding of what "complete" means — mirrored here by the "What done is not" section, which closes the empiricism gap that "done later" creates.
- **Google Engineering Practices — The Standard of Code Review** (google.github.io/eng-practices): a change is approvable once it definitely improves overall code health (functionality, complexity, tests, no code-health regression) — grounds item 4's self-review against the full diff and the "checklist IS the reviewer" stance for solo+AI work.
- **Modern code review evidence** (SmartBear/Cisco study; Bacchelli & Bird, *Expectations, Outcomes, and Challenges of Modern Code Review*, ICSE 2013): review's primary value is shared understanding and defect-finding, not just bug count — supports requiring author self-review even absent a second human reviewer.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (all required jobs) + stacks/nextjs-default/ci/PULL_REQUEST_TEMPLATE.md (required checkboxes)
- Fallback if unenforceable: n/a — mechanical items are CI-enforced; judgment items (scope, self-review honesty) are carried by the PR template checkboxes and the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: `PULL_REQUEST_TEMPLATE.md` at the project root (GitHub picks it up for every PR) and the CI workflows that enforce items 2–3 and 6–7 mechanically.
