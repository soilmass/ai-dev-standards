# Task Decomposition

How a spec becomes a sequence of small, shippable units. Decomposition quality is the single biggest lever on AI-agent output quality: small tasks keep the context tight, the diff reviewable, and the blast radius of a wrong turn contained.

## Rules

1. **One concern per PR.** A PR does exactly one of: add a behavior, fix a defect, refactor structure, update dependencies, change config. Mixing concerns hides regressions in noise.
2. **Every unit is shippable.** After each PR merges, `main` is releasable: the unit includes its tests, docs, and migration. "Part 1 of 3 (broken until part 3)" is not a unit — use a feature flag to keep incomplete features dark in production (`06-delivery/release-process.md`).
3. **Vertical slices over horizontal layers.** Split by user-visible capability (one flow end-to-end), not by layer ("all the models, then all the endpoints"). A slice proves integration immediately.
4. **Sequence by risk.** Do the unit that could invalidate the design first — the unknown integration, the performance question — not the easy CRUD. To surface the risks worth sequencing first, check the trigger conditions in `03-design/threat-modeling.md` before ordering; a threat model that's due is a design input that shapes the sequence, not a code-review afterthought.
5. **Write the decomposition into the spec** (the spec template has a section for it) before the first PR; renegotiate it explicitly when reality disagrees.

## Sizing heuristics

- A unit an experienced developer (or an agent run) can complete — code, tests, docs — in **half a day or less**.
- Diff budget: aim under ~400 changed lines; the CI gate hard-fails above 800 — i.e. 801+ (excluding lockfile/snapshots). When generated code legitimately exceeds it, split the generated commit from the hand-written one.
- If you can't name the unit in one short sentence without "and", it's two units.
- If the test plan needs a table of contents, it's an epic — decompose again.

## Agent contract

- An agent given an oversized task splits it and proposes the sequence rather than starting (`00-governance/agent-operating-rules.md` §2).
- Each agent run gets one unit; "while I'm here" expansions are scope creep and get split out.

## Standards basis

- **INVEST (Bill Wake, 2003)** — Independent, Small, and Estimable are the unit test for a decomposition: a unit that can't ship without another is not Independent; one that can't be named in a sentence is not Small; one too large to estimate must be split. See [Agile Alliance: INVEST](https://agilealliance.org/glossary/invest/).
- **User-story mapping & the walking skeleton (Jeff Patton; skeleton term from Alistair Cockburn)** — split by user-visible capability into thin end-to-end slices; build the barest end-to-end path first to prove integration and surface technical risk. Grounds "vertical slices over horizontal layers" and "sequence by risk." See [jpattonassociates.com: the new backlog is a map](https://jpattonassociates.com/the-new-backlog/).
- **Working in small batches (DORA / Accelerate, Forsgren–Humble–Kim)** — small batches shorten feedback, cut variability and risk, and raise deployment frequency; the diff budget and "one unit per agent run" encode this. A unit completable in hours-to-days is DORA's own small-batch sizing. See [dora.dev: working in small batches](https://dora.dev/capabilities/working-in-small-batches/).
- **Scrum Guide 2020 — Product Backlog refinement** — "breaking down and further defining items into smaller, more precise items" until each is Done within one cycle; this doc applies that to PR-sized shippable units. See [scrumguides.org](https://scrumguides.org/scrum-guide.html).

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (pr-size job: hard limit on changed lines)
- Fallback if unenforceable: n/a — the size gate is CI-enforced; one-concern judgment is carried by the spec's scope fallback in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the PR workflow containing the pr-size gate (limit documented in the job's env).
