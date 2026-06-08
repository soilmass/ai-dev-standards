# Documentation Spine

Docs are part of the change, not a chore after it. The rule that makes everything else work: **docs update in the same PR as the code they describe** — enforced by the CI docs-check. This spine says what each layer must write down and where.

## What each layer writes, and where

| Layer | Must write down | Artifact |
|---|---|---|
| 00 Governance | Why the rules are what they are; decisions and their dates | this library; `00-governance/pinned-decisions.md` |
| 01 Context | Project identity and agent entry point; system shape; ubiquitous language; consequential decisions | project `CLAUDE.md`; `docs/architecture-map.md`; `docs/glossary.md`; ADRs |
| 02 Product | The problem, scope, non-goals, and testable criteria — before building | `docs/spec-*.md` per feature |
| 03 Design | Threat models for qualifying features; contract shapes (schemas are the doc) | `docs/threat-model-*.md`; schema modules |
| 04 Build | Why-comments where code can't speak; test intent in test names | in the code itself |
| 05 Verification | Self-review notes: justified misses, per PR | the PR description (template section) |
| 06 Delivery | Rollback path per PR; changelog per release; migration intent in migration review | PR description; generated changelog |
| 07 Operations | Runbooks per failure scenario; SLOs + RPO/RTO; verified-restore log | `docs/incident-runbook-*.md`; `docs/slos.md`; ops log |
| 08 Maintenance | The debt log; deprecation markers with dates and replacements | `docs/debt-log.md`; at the declaration site |

## The docs-updated rule

1. A PR that changes behavior, structure, or operations updates the affected artifacts above **in the same PR**. The CI docs-check fails code-only diffs; the `no-docs-needed` label is the conscious waiver, and waiving dishonestly is a review violation.
2. New component/boundary/external dependency → architecture map row. New domain concept → glossary entry. New failure mode → runbook. Decision a future reader will question → ADR.
3. Docs that describe removed things are removed with them (`08-maintenance/deprecation-process.md` step 4).

## Writing rules

4. **Closest-to-use wins:** prefer the doc the reader is already looking at — code comment over README over wiki. External wikis and drive docs are where truth goes to fork; everything lives in the repo.
5. Docs state *why* and *what must hold*; they don't narrate code line-by-line (that doc is stale by the next PR).
6. Templates exist so the blank page never blocks: copy, fill the `<ANGLE_BRACKETS>`, delete sections that don't apply — a section consciously deleted beats one emptily present.
7. Agents treat doc updates as part of "done" (`05-verification/definition-of-done.md` item 5) and may trust the docs they read to be current — that's the contract this spine maintains.

## Reader-need shape (which doc, for whom)

8. Documentation serves four distinct reader needs; conflating them is the most common doc failure. Match the artifact to the need: **tutorial** (learning-oriented, takes a newcomer by the hand), **how-to guide** (task-oriented, an already-competent reader pursuing a goal), **reference** (information-oriented, accurate and complete — schemas and the architecture map are reference), **explanation** (understanding-oriented — ADRs and the *why* in this spine are explanation). A page that tries to teach and to be a complete reference at once does neither well; split it.

## Standards basis

- **Diátaxis** (diataxis.fr, Daniele Procida) — the four-mode reader-need model in rule 8: tutorials / how-to / reference / explanation, each with a distinct purpose (learning vs. task vs. information vs. understanding). This spine's per-layer artifacts already partition along these lines — specs and runbooks are how-to/reference, ADRs and the *why*-rules are explanation, schemas are reference.
- **Architecture Decision Records** (Michael Nygard, 2011, "Documenting Architecture Decisions"; adr.github.io) — a short immutable record per consequential decision with Status / Context / Decision / Consequences; numbered, markdown, stored in-repo (canonically `doc/adr`). Basis for rule 2's "decision a future reader will question → ADR" and the ADR artifact in layer 01; `01-context/adr.template.md` follows the Nygard structure.
- **Docs-as-code** — docs live in the repo, version-controlled, reviewed and diffed alongside code, built/checked in CI. This is the foundation of the same-PR rule (intro), rule 4 (closest-to-use / everything in the repo), and the CI docs-check enforcement below.
- **C4 model** (Simon Brown, c4model.com) — Context / Container / Component / Code hierarchy for architecture diagrams at chosen zoom levels; the basis for `docs/architecture-map.md` being a layered map rather than one undifferentiated diagram. New component/boundary → an architecture-map row (rule 2) corresponds to a C4 Container/Component entry.
- **README / CONTRIBUTING conventions** (community standard; e.g. GitHub community-profile, Standard Readme) — a project's entry-point README and contributor guide are first-class artifacts; rule 4's "closest-to-use wins" ranks README above wiki precisely because it ships with the code.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (docs job: code-without-docs diffs fail unless the waiver label is applied)
- Fallback if unenforceable: n/a — presence is CI-enforced; content quality is carried by the runbook/debt/SLO fallback lines already in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the docs/ template set (ADR, glossary, architecture map, spec, threat model, incident runbook) and the PR workflow containing the docs-check.
