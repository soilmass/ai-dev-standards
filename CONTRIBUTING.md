# Contributing to ai-dev-standards

This is a **solo-maintained** standards library with a deliberate operating model
that differs from the project standards it ships — see
`00-governance/repo-operating-model.md` for the full, justified record. Read these
before changing anything:

- `CLAUDE.md` — the rules for editing the library (footer contract, never-stub,
  rules-vs-choices, phased-build).
- `00-governance/standards-lifecycle.md` — how a standard is proposed, changed,
  versioned, deprecated, and how project lessons flow back.
- `_spines/version-control.md` — the git/GitHub posture this repo teaches (and,
  per the operating-model doc, which parts it adopts for itself).

## How changes happen here

- The library **commits direct to `main`** — no feature branches, no pull requests
  for its own development. The human maintainer is the final arbiter and makes
  every commit (`00-governance/standards-lifecycle.md` §7).
- AI agents may **propose and prepare** a change (a working-tree draft with
  rationale) but never commit on their own authority.
- **Patch, don't rebuild:** the unit of change is the smallest edit that encodes
  the lesson. A doc and the config it points at change in the **same commit**.
- Commit messages follow **Conventional Commits**; releases are git tags
  (`vYYYY.MM[.N]`, `00-governance/standards-lifecycle.md` §4).
- The gate is `scripts/suite-ci.sh` — run it before committing (CI also runs it on
  every push and PR): footers, calibration register, flow-back ledger, internal
  links, fragment anchors, config validity, bootstrap smoke, and preset coherence.

## Reporting

- Friction found while *using* the library on a real project flows back through
  that project's debt-log "Library flow-back" section and into
  `00-governance/flow-back-log.md` — not by editing the library mid-task.
- Security issues: see `SECURITY.md`.
