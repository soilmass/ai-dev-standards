# CLAUDE.md — rules for agents working ON this repo

This file governs edits to the **standards library itself**. It is distinct from `01-context/CLAUDE.template.md`, which projects consume. If you are working in a project bootstrapped *from* this library, this file does not apply to you.

## 1. The footer contract

Every layer doc in `02-product/` through `08-maintenance/` and `_spines/` MUST end with this exact footer (headings verbatim):

```
## Enforcement
- Mechanism: <lint rule | CI job | git hook | runtime check | none-possible>
- Config: stacks/<stack>/<path>   (or "n/a")
- Fallback if unenforceable: <specific AI self-review checklist line>

## Bootstrap
- What new-project.sh injects for this standard (or "nothing — reference only")
```

- If `Mechanism: none-possible`, the `Fallback` line is **required** and MUST also appear **verbatim** as a checklist item in `05-verification/code-review-standard.md`. Adding or changing a fallback means updating both files in the same commit.
- Docs in `00-governance/` and `01-context/` do not carry the footer.
- `scripts/audit-completeness.sh` checks footer presence; run it after any layer-doc change.

## 2. The never-stub rule

Write real content, not placeholders. No `TODO`, no "describe here", no empty sections — anywhere. The single exception: fill-in blanks inside `*.template.md` files, which are the point of a template and MUST be marked with `<ANGLE_BRACKETS>`.

## 3. Where things go: rules vs choices

- **GLOBAL = RULES; PROJECT = CHOICES.** No framework names, versions, or project-specific values in any file outside `stacks/`. If a value is a *choice* rather than a *rule*, it belongs in a stack preset.
- Exceptions, both documented: `00-governance/pinned-decisions.md` (the standing recommendations, framed as defaults + rules) and the three verbatim governance guardrails in `00-governance/agent-operating-rules.md`.
- Prefer enforcement over prose: when a rule can be a config, write the config in the stack preset and have the doc point at it via the footer.
- A new tool decision = a new ADR in the relevant preset's `stack-decisions.md`, plus (if it changes a default) a patch to `pinned-decisions.md`.

## 4. Phased-build expectation

Structural changes to this library are built **in phases with verification gates**, never as a single dump:

1. Skeleton/structure first, then governance spine.
2. Enforcement configs (preset + scripts) **before** the prose docs that reference them.
3. `05-verification/code-review-standard.md` is written/updated **after** the docs it aggregates fallbacks from.
4. After every phase: run `scripts/audit-completeness.sh`, verify the tree against the README table of contents, and update `00-governance/completeness-matrix.md`.

## 5. Change discipline

- Patch, don't rebuild — see `00-governance/standards-lifecycle.md`. The smallest edit that encodes the lesson wins.
- A doc and the preset config it points at must change in the same commit; they must never drift.
- **Every tunable knob lives in the calibration register.** Changing any threshold, budget, cadence, score floor, or version pin means updating its row (value + rationale + recalibration trigger) in `00-governance/calibration.md` — and its manifest entry — in the same commit. `scripts/check-calibration.sh` (run by suite CI) fails on any disagreement between the register and the tree. Adding a new knob means adding its row + manifest entry.
- Templates keep their `.template.md` suffix; renaming one breaks `scripts/new-project.sh` — update the script in the same commit if a template is added, renamed, or removed.
- Keep `01-context/CLAUDE.template.md` **lean**: non-negotiable rules inline, everything else linked. It is an index, not a manual; resist additions that belong in a layer doc.
