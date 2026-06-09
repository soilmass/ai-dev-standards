# This Repo's Git/GitHub Operating Model

This library *ships* a git/GitHub standard (`_spines/version-control.md`, `04-build/git-standards.md`, `06-delivery/release-process.md`) for the projects it bootstraps. It also **operates differently from that standard on purpose** — it is a solo documentation library, not a deployed application. Per root `CLAUDE.md`, the layer standards govern *consuming projects, not this repo's own operation*.

This doc makes that divergence **explicit and justified** rather than silent: it records, rule by rule, what this repo **follows**, **adapts**, or **waives** versus the standard it ships, and why. "Aligned" for this repo means *documented, justified divergence* — the same bar the standard sets for any deviation (`03-design/architecture-standards.md` rules 11–13: a deviation is an ADR or logged debt, never silent).

## Rule-by-rule

| Standard (shipped) | This repo | Why |
|---|---|---|
| Conventional Commits — `<type>(<scope>): <subject>`, ≤72 (`git-standards.md` rule 5) | **Follows** | History is already Conventional Commits; it keeps `git log` scannable and lets the tag/changelog discipline work. |
| One logical change per commit (`git-standards.md` rule 7) | **Follows** (as "one enforcement-altering batch per commit/tag") | Matches the phased-build expectation in `CLAUDE.md` §4 and the versioning rule below. |
| Trunk-based, short-lived branches + PRs; no direct commits to `main` (`git-standards.md` rules 1–4, 8–11) | **Waives** | Solo repo. A branch + PR for a one-person library with a single CI gate adds ceremony without a second reviewer. Proposals live as working-tree drafts the human reviews, then commits direct to `main` (`standards-lifecycle.md` §2, §7). The `/batch`-style PR fan-out does not apply here. |
| Required PR checks + definition-of-done gate via branch protection (`ci-pipeline.md`, `code-review-standard.md`) | **Adapts** | No PRs, so the DoD/self-review discipline is applied by the human at commit time. `suite-ci.yml` runs `scripts/suite-ci.sh` on **push and PR** as the one authoritative gate (`CLAUDE.md`). |
| Commit & tag **signing**; "require signed commits" (`_spines/version-control.md` rules 1–3) | **Deferred (accepted, with trigger)** | The library ships the signing standard, the `configure-signing.sh` helper, and required-signature enforcement *for consuming projects*. This repo's own commits/tags are currently **unsigned** (verified 2026-06-08). Trigger to adopt: when the repo gains a second committer or any external contributor, or at the next currency pass — whichever comes first. Recorded here so the gap is honest, not invisible. |
| Tags `vYYYY.MM[.N]`, human-tagged, versioned-as-a-whole (`standards-lifecycle.md` §4) | **Follows** | The repo is versioned as a whole by git history; tags mark enforcement-altering batches. `check-flowback.sh` already depends on `patched` rows naming real tags. |
| Tag protection (no deletion / non-fast-forward) (`_spines/version-control.md` rule 3) | **Recommended, host-side** | Worth enabling on `refs/tags/v*` via repo settings so a released tag can't be re-pointed; not bootstrap-settable. Optional for solo, but cheap insurance given tags are the flow-back ledger's anchors. |
| Generated changelog + GitHub Releases on tag (`release-process.md` rule 4) | **Adapts / N/A** | This repo ships no `release.yml` for itself: tags are the release markers, and the commit history *is* the changelog for a docs library. The release tooling is a consuming-project concern. |
| Package publishing — npm provenance, publish metadata (`_spines/version-control.md` rules 9–12) | **N/A** | Not published to a registry; it is consumed by cloning + `scripts/new-project.sh`, not `npm install`. No `package.json`. |
| Dependency updates / Dependabot (`dependency-updates.md`) | **N/A** | The repo has no package dependencies — only markdown, bash, and `.example` configs. Its CI uses a small set of pinned GitHub Actions, reviewed by hand. |
| `.gitignore`, `.gitattributes`, `LICENSE`, `SECURITY.md`, `CONTRIBUTING.md` (`_spines/version-control.md` rules 6–8) | **Follows** (added in this batch) | The repo now ships its own hygiene + community-health files; `CONTRIBUTING.md` documents *this* model (not the consuming-project PR flow), and `SECURITY.md` routes to private disclosure. `CODEOWNERS` is omitted (a single owner owns everything). |
| Branch protection requiring the CI gate on `main` | **Recommended, host-side** | Enabling "require `suite-ci` to pass" on `main` is sound even for a solo repo (it stops a red push landing). Not bootstrap-settable; left to the maintainer. |

## The standing rule

When this repo's operation diverges further from the standard it ships, **update this table in the same commit** — the divergence must always be one of *follows / adapts / waives / deferred-with-trigger / N/A*, never undocumented. This is the repo-level application of "a deviation is recorded, never silent" (`03-design/architecture-standards.md` rule 11, `08-maintenance/tech-debt-policy.md`).
