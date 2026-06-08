# Definition of Ready / Done (Product-Item Gate)

The two gates on a product item: *should we start it* (Ready) and *is it a done increment* (Done). This is the **product-item** gate — decided in refinement and at item close — not the **engineering** merge gate. The per-PR merge checklist lives in `05-verification/definition-of-done.md`; this doc does not restate it.

Keep the layers straight:
- **Ready / Done (this doc)** — is the *item* well-formed enough to start, and does the shipped result deliver the *user-visible* outcome the item promised.
- **Acceptance criteria** (`02-product/acceptance-criteria.md`) — the per-item checkable contract; a subset of both gates below.
- **Definition of Done, merge gate** (`05-verification/definition-of-done.md`) — engineering done for one PR (tests green, reviewed, reversible). An item's PRs each pass that gate; the item is not Done until *all* of them are merged and the outcome holds end-to-end.

## Readiness is heuristics, not a gate

Do **not** build a formal, mandatory "Definition of Ready" checklist that an item must 100% satisfy before work may start. That is a known anti-pattern: a hard readiness gate becomes a stage-gate handoff, blocks overlapping work, shifts value/ordering decisions away from the product owner, and pushes the team back toward waterfall. The Scrum Guide deliberately defines no "Definition of Ready."

Treat readiness as a **conversation aid**, applied with judgment:

1. **Outcome named.** The item states the user-visible change and why it matters — not a solution disguised as a requirement.
2. **Small enough.** Plausibly completable within one cycle (`02-product/task-decomposition.md` sizing). If not, it is refined, not started.
3. **Enough criteria to begin.** At least the happy path is expressible as checkable acceptance criteria (`02-product/acceptance-criteria.md`); remaining detail can be resolved collaboratively *during* the work.
4. **No blocking unknown.** The one question that could invalidate the approach is identified — and either answered or made the first thing the work attacks (`02-product/task-decomposition.md` rule 4).
5. **Dependencies visible.** External blockers (data, access, a decision owed) are named, not discovered mid-flight.

Rules for using these:
- A "rough mock-up started, open issues resolvable in-flight" item **is** ready. Demanding everything finished up front is the anti-pattern.
- An item failing a heuristic triggers *refinement or a question*, never an automatic block — the product owner may still pull it forward to maximize value.
- Refinement is continuous, not a phase: break items down and add detail (description, order, size) as an ongoing activity.

## Done is the increment commitment

An item is **Done** when the promised user-visible outcome is true in a releasable increment — the product-level mirror of the engineering merge gate.

An item is Done when:

1. **Every acceptance criterion passes** (`02-product/acceptance-criteria.md`), including the unhappy paths, not only the happy one that made it Ready.
2. **All its PRs are merged and each passed the merge gate** (`05-verification/definition-of-done.md`). One green PR does not make a multi-PR item Done.
3. **The outcome holds end-to-end** — the user-visible flow works against the integrated system, not just in isolation (`02-product/task-decomposition.md` rule 3, vertical slices).
4. **It is releasable, not "release later."** If gated behind a flag, the flag and its rollout/rollback are specified (`06-delivery/release-process.md`); "done except for deploy" is not Done.
5. **No undisclosed remainder.** Deferred work is split into its own tracked item, not carried as an invisible IOU. "Done" with a hidden tail breaks transparency.

Done is teamwide and stable, not renegotiated per item to make a laggard pass. Tightening Done is a deliberate change, not a convenience.

## What this gate is not

- Not the merge gate. A merged PR is engineering-done; the *item* can still be unfinished (more PRs, integration not proven, criteria unmet).
- Not "the agent says it's done." Done is the criteria passing and the outcome holding — observable, not asserted.
- Not a place to relitigate scope. Scope and non-goals are the spec's (`02-product/spec.template.md`); this gate checks the agreed item, not a redefined one.

## Standards basis

- **Scrum Guide 2020 — Definition of Done as the Increment's commitment** (scrumguides.org): "a formal description of the state of the Increment when it meets the quality measures required for the product," which "creates transparency by providing everyone a shared understanding of what work was completed." Grounds "Done is the increment commitment" and the no-undisclosed-remainder / teamwide-stability rules. See [scrumguides.org](https://scrumguides.org/scrum-guide.html).
- **Scrum Guide 2020 — Product Backlog refinement and readiness** (scrumguides.org): refinement is "the act of breaking down and further defining Product Backlog items into smaller more precise items"; items "that can be Done by the Scrum Team within one Sprint are deemed ready for selection… They usually acquire this degree of transparency after refining activities." Grounds the readiness heuristics and "refinement is continuous." The guide defines **no** formal Definition of Ready — basis for framing readiness as heuristics, not a gate. See [scrumguides.org](https://scrumguides.org/scrum-guide.html).
- **Definition of Ready as anti-pattern** (Mike Cohn / Mountain Goat Software, *The Dangers of a Definition of Ready*): a rigid DoR is "a huge step towards a sequential, stage-gate approach," blocks overlapping work, and is "unnecessary process overhead"; use guidelines not rules and permit partial completion (e.g. rough mock-ups, open issues resolved in-iteration). Grounds the entire "Readiness is heuristics, not a gate" section. See [mountaingoatsoftware.com](https://www.mountaingoatsoftware.com/blog/the-dangers-of-a-definition-of-ready).
- **Definition of Ready and value blocking** (Scrum.org / Professional Scrum): a hard DoR can shift value- and order-decisions from the Product Owner to Developers and constrain the PO's ability to pivot for value. Grounds rule "the product owner may still pull it forward to maximize value." See [scrum.org: Walking Through a Definition of Ready](https://www.scrum.org/resources/blog/walking-through-definition-ready).
- **INVEST — Small & Testable** (Bill Wake, 2003): an item too large to finish in a cycle, or with no checkable criterion, is not ready to start; grounds readiness heuristics 2–3. See [Agile Alliance: INVEST](https://www.agilealliance.org/glossary/invest/).

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: This item meets the lightweight readiness heuristics before starting, and is closed as Done only when every acceptance criterion passes and the user-visible outcome holds end-to-end across all its merged PRs.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only.
