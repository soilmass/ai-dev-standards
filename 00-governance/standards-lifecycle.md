# Standards Lifecycle

How a standard in this library is proposed, changed, versioned, and deprecated — and how lessons from real projects flow back in. The prime directive: **patch, don't rebuild**. A library that gets rewritten every time it disappoints stops being a source of truth.

---

## 1. States of a standard

| State | Meaning |
|---|---|
| **Active** | In force. Linked from `completeness-matrix.md`. |
| **Proposed** | Drafted in a branch/PR against this repo; not yet binding. |
| **Deprecated** | Still present, marked `> **DEPRECATED:** superseded by <link>` at the top; binding only for projects that haven't migrated. |
| **Removed** | Deleted after every consuming project has migrated; the removal commit message records why. |

## 2. Proposing a new standard

1. Confirm the gap is real: check `completeness-matrix.md` — is the cell empty or marked as a gap?
2. Write the doc in the correct layer folder. If it is a layer doc (`02`–`08`, `_spines`), it MUST carry the Enforcement/Bootstrap footer (see root `CLAUDE.md`).
3. Wire enforcement first where possible: add the config to the relevant stack preset, then point the doc at it.
4. Update `completeness-matrix.md` and run `scripts/audit-completeness.sh`.
5. Open a PR against this repo. The PR description states which projects prompted the standard.

## 3. Changing an existing standard — patch, don't rebuild

- The unit of change is the **smallest edit that encodes the lesson**: a new bullet, a tightened threshold, a new checklist line. Not a rewrite.
- A change that alters enforcement (config, CI gate, hook) updates the doc and the preset config **in the same commit** — they must never drift apart.
- A change that adds a `none-possible` fallback line must add the same line verbatim to `05-verification/code-review-standard.md` (the aggregation rule in root `CLAUDE.md`).
- Rewrites are reserved for standards whose core premise is invalid. Justify in the PR with the failures the old version caused.

## 4. Versioning

- The library is versioned **as a whole** by git history; individual docs are not version-stamped.
- Tag the repo (`vYYYY.MM`) after any change-batch that alters enforcement behavior, so a project can record which library snapshot it bootstrapped from.
- Projects record their bootstrap snapshot in their `CLAUDE.md` (the bootstrap script stamps the date); they upgrade by re-diffing against the current library, not by silently inheriting changes.

## 5. Deprecating a standard

1. Mark the doc `DEPRECATED` with a pointer to its replacement (or to the rationale if there is none).
2. Update `completeness-matrix.md` so the cell points at the replacement.
3. Keep the deprecated file for at least one tag cycle so in-flight projects can still resolve links.
4. Remove it once no active project references it; the removal commit explains why.

## 6. Feedback loop — how project lessons flow back

The library improves only through this loop:

1. **During a project**, friction with a standard is logged in the project's decision log / debt log — not fixed by editing the library mid-task (agents: see the never-touch list in `agent-operating-rules.md`).
2. **After the work ships**, review the log entries. Each becomes one of: a patch PR to the relevant doc, a preset config change, a new ADR in the stack, or a conscious "no change" with a one-line reason.
3. **Currency pass**: at least twice a year, re-verify the time-sensitive claims in `pinned-decisions.md` and the dated guardrails in `agent-operating-rules.md` (each carries its verification date). In the same pass, walk the calibration register (`calibration.md`): check each knob's recalibration trigger against observed project data and run `scripts/check-calibration.sh`. Update the snapshot date when done.
4. Run `scripts/audit-completeness.sh` after every change-batch; the matrix and the tree must never disagree.

## 7. Who decides

This is a solo-developer library: the human is the final arbiter. AI agents may **propose** lifecycle changes (a drafted PR with rationale) but never merge changes to this repo on their own authority.
