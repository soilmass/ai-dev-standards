# Release Process

How shipped code becomes a release: versioning, changelog, and feature flags. Built on the machine-parseable history that the commit standard guarantees. The git/GitHub *mechanics* that carry a release — `v`-prefixed **signed, protected** tags, GitHub Releases creation, and **package publishing** (npm provenance + publish metadata) — are owned by `_spines/version-control.md`; this doc owns the versioning *scheme*, the changelog, and feature flags.

## Versioning

1. Applications version by **release date + sequence** (`2026.06.1`) or auto-incremented build — semantic versioning is for libraries with consumers; an app's "breaking change" is a user-facing matter, handled by flags and comms, not version math.
2. Anything published for external consumption (a package, a public API) uses semver, strictly.
3. Every production deploy is traceable: the deploy records the commit SHA; a release tag marks anything announced or referenced later.

## Changelog

4. The changelog is **generated from Conventional Commits** (`feat`/`fix` land in it; `chore`/`ci` don't) — this is why the commit-format check is a hook, not advice. The preset ships a tag-triggered release workflow that generates the release notes; hand-curate the user-facing summary for announced releases on top of it, never hand-maintain the raw list.
5. Each entry links its PR; reverts reference what they reverted.

## Feature flags

6. Incomplete or risky features ship **dark**: merged, deployed, flagged off. This is what makes one-concern-per-PR compatible with always-releasable `main` (`02-product/task-decomposition.md` rule 2).
7. Start with the simplest flag that works (env-schema-validated config read at boot); adopt a flag service only when runtime toggling or percentage rollout is actually needed — via ADR.
8. Every flag has an owner and a removal condition stated where it's declared. A flag that's been 100%-on for a release cycle is debt: remove it (`08-maintenance/tech-debt-policy.md`).
9. Kill-switch flags for risky integrations are part of the rollback story (`06-delivery/rollback.md`).

The minimal flag, concretely: a boot-validated env var (e.g. `FLAG_NEW_CHECKOUT`), parsed as a boolean by the env schema so an invalid value fails startup, not a request. Read it **once at the server boundary** and pass the resolved value down — never re-read the env or sniff the flag ad hoc deep in components, where it can drift between call sites (`04-build/secrets-config.md`). A kill switch is the same pattern with a degrade-gracefully branch: flag off → the safe fallback path, not an error.

## Release steps (the whole ceremony)

1. Confirm the nightly/pre-deploy tier is green on the release commit (`05-verification/ci-pipeline.md`).
2. Merge → automatic deploy (`06-delivery/deployment-strategy.md`).
3. Tag + generate changelog for announced releases.
4. Watch the dashboards for one error-budget-relevant interval (`07-operations/observability.md`, `slo-error-budgets.md`).

## Standards basis

- **Semantic Versioning 2.0.0** (semver.org) — `MAJOR.MINOR.PATCH`; MAJOR for incompatible API changes, MINOR for backward-compatible additions, PATCH for backward-compatible fixes; requires a declared public API. Aligns: applied strictly to anything published for external consumption (rule 2); apps use date-based versioning since they expose no consumer API.
- **Calendar Versioning** (calver.org) — date-derived version schemes for software whose cadence, not API contract, is the meaningful axis. Aligns: app version `YYYY.0M.sequence` (rule 1).
- **Conventional Commits 1.0.0** (conventionalcommits.org) — structured commit prefixes (`feat`/`fix`/`chore`…) make history machine-parseable and drive automated version + changelog derivation. Aligns: the commit-msg hook and changelog generation rest on it.
- **Keep a Changelog 1.1.0** (keepachangelog.com) — human-curated, grouped, chronologically-descending change notes; "don't let your changelog be a dump of commit logs." Aligns: hand-curate the user-facing summary on top of generated notes for announced releases.
- **Feature Toggles** (Hodgson on martinfowler.com/articles/feature-toggles.html) — categorize toggles by longevity/dynamism (release, ops, experiment, permission); release toggles are short-lived and must be retired. Aligns: every flag has an owner + removal condition; a long-on flag is debt.
- **Progressive delivery** (getunleash.io / DORA) — extends CD by exposing changes to expanding user cohorts (percentage rollout, rings) with metric-gated promotion. Aligns: adopt a flag service only when runtime toggling / percentage rollout is genuinely needed (rule 7).

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/commitlint.config.mjs (commit-msg hook guarantees release-parseable history) + stacks/nextjs-default/ci/release.yml (tag-triggered workflow that actually generates the release notes from it)
- Fallback if unenforceable: n/a — history parseability is hook-enforced and note generation is workflow-automated; flag-removal discipline is carried by the tech-debt fallback line in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the commit-msg hook + commitlint config, and the release workflow into `.github/workflows/` — pushing a version tag produces the generated changelog from the first release.
