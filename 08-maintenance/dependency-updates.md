# Dependency Updates

Staying current is cheaper than catching up: small weekly updates each carry near-zero risk; a six-month gap is a migration project with security exposure attached. Entry/vetting rules live in `04-build/dependency-policy.md`; this doc is the *cadence* side.

## Cadence

1. **Automated update PRs, weekly**, opened by the platform's update bot per the preset's config: minor + patch updates arrive grouped (one PR, one review), majors arrive individually.
2. **Security updates land immediately**, outside the weekly rhythm — a vulnerability-fix PR is reviewed the day it opens (severity high+ is already blocking merges via the audit gate).
3. The weekly batch is processed within the week. Update PRs left to rot accumulate conflicts and normalize ignoring the bot — if a PR is deliberately skipped, close it with a comment, don't let it stale.

## Handling update PRs

4. Grouped minor/patch PR: green CI is sufficient evidence — merge. The test suite and gates exist precisely so these are boring.
5. Major-version PR: read the changelog/migration notes first; if code changes are needed they ship **in the same PR** as the bump, sized per `02-product/task-decomposition.md`. If the migration is large, it gets a spec.
6. An update that breaks CI is not "flaky" — it found something. Fix the code or pin-with-ADR (accepted-risk, with expiry); never merge red, never disable the failing test to merge an update.
7. Framework majors and anything on the pinned-decisions table additionally get a glance at `00-governance/pinned-decisions.md` — if the ecosystem has moved (tool deprecated, default shifted), that's a lifecycle patch, not just a version bump.

## Tooling rule

8. Update automation is configured **in the repo** (the preset ships the config) so cadence and grouping are reviewable like everything else. Per the pinned-decisions deviation rule, switch tooling only when grouping/policy needs outgrow it — as a preset change.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/dependabot.yml (weekly grouped update PRs) + stacks/nextjs-default/ci/pr.yml (deps job gates every update PR like any other)
- Fallback if unenforceable: n/a — PR generation is platform-automated and each update PR passes the full pipeline; the process-the-batch habit is carried by the weekly rhythm, visible as open-PR count.

## Bootstrap
- What new-project.sh injects for this standard: `.github/dependabot.yml` from the preset.
