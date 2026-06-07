# Release Process

How shipped code becomes a release: versioning, changelog, and feature flags. Built on the machine-parseable history that the commit standard guarantees.

## Versioning

1. Applications version by **release date + sequence** (`2026.06.1`) or auto-incremented build — semantic versioning is for libraries with consumers; an app's "breaking change" is a user-facing matter, handled by flags and comms, not version math.
2. Anything published for external consumption (a package, a public API) uses semver, strictly.
3. Every production deploy is traceable: the deploy records the commit SHA; a release tag marks anything announced or referenced later.

## Changelog

4. The changelog is **generated from Conventional Commits** (`feat`/`fix` land in it; `chore`/`ci` don't) — this is why the commit-format check is a hook, not advice. Hand-curate the user-facing summary for announced releases; never hand-maintain the raw list.
5. Each entry links its PR; reverts reference what they reverted.

## Feature flags

6. Incomplete or risky features ship **dark**: merged, deployed, flagged off. This is what makes one-concern-per-PR compatible with always-releasable `main` (`02-product/task-decomposition.md` rule 2).
7. Start with the simplest flag that works (env-schema-validated config read at boot); adopt a flag service only when runtime toggling or percentage rollout is actually needed — via ADR.
8. Every flag has an owner and a removal condition stated where it's declared. A flag that's been 100%-on for a release cycle is debt: remove it (`08-maintenance/tech-debt-policy.md`).
9. Kill-switch flags for risky integrations are part of the rollback story (`06-delivery/rollback.md`).

## Release steps (the whole ceremony)

1. Confirm the nightly/pre-deploy tier is green on the release commit (`05-verification/ci-pipeline.md`).
2. Merge → automatic deploy (`06-delivery/deployment-strategy.md`).
3. Tag + generate changelog for announced releases.
4. Watch the dashboards for one error-budget-relevant interval (`07-operations/observability.md`, `slo-error-budgets.md`).

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/commitlint.config.mjs (commit-msg hook guarantees release-parseable history; changelog generation and tagging consume it)
- Fallback if unenforceable: n/a — history parseability is hook-enforced; flag-removal discipline is carried by the tech-debt fallback line in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: the commit-msg hook and commitlint config that make generated changelogs possible from the first commit.
