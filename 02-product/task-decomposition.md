# Task Decomposition

How a spec becomes a sequence of small, shippable units. Decomposition quality is the single biggest lever on AI-agent output quality: small tasks keep the context tight, the diff reviewable, and the blast radius of a wrong turn contained.

## Rules

1. **One concern per PR.** A PR does exactly one of: add a behavior, fix a defect, refactor structure, update dependencies, change config. Mixing concerns hides regressions in noise.
2. **Every unit is shippable.** After each PR merges, `main` is releasable: the unit includes its tests, docs, and migration. "Part 1 of 3 (broken until part 3)" is not a unit — use a feature flag to keep incomplete features dark in production (`06-delivery/release-process.md`).
3. **Vertical slices over horizontal layers.** Split by user-visible capability (one flow end-to-end), not by layer ("all the models, then all the endpoints"). A slice proves integration immediately.
4. **Sequence by risk.** Do the unit that could invalidate the design first — the unknown integration, the performance question — not the easy CRUD.
5. **Write the decomposition into the spec** (the spec template has a section for it) before the first PR; renegotiate it explicitly when reality disagrees.

## Sizing heuristics

- A unit an experienced developer (or an agent run) can complete — code, tests, docs — in **half a day or less**.
- Diff budget: aim under ~400 changed lines; the CI gate hard-fails at 800 (excluding lockfile/snapshots). When generated code legitimately exceeds it, split the generated commit from the hand-written one.
- If you can't name the unit in one short sentence without "and", it's two units.
- If the test plan needs a table of contents, it's an epic — decompose again.

## Agent contract

- An agent given an oversized task splits it and proposes the sequence rather than starting (`00-governance/agent-operating-rules.md` §2).
- Each agent run gets one unit; "while I'm here" expansions are scope creep and get split out.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (pr-size job: hard limit on changed lines)
- Fallback if unenforceable: n/a — the size gate is CI-enforced; one-concern judgment is carried by the spec's scope fallback in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the PR workflow containing the pr-size gate (limit documented in the job's env).
