# Dependency Policy

Every dependency is code you now own without having written. This doc governs how deps enter, stay in, and leave a project. Update *cadence* is the maintenance side — see `08-maintenance/dependency-updates.md`.

## Adding a dependency

1. **Adding/removing a dependency is an ask-first action for agents** (`00-governance/agent-operating-rules.md` §2). Humans add deps via a PR that states the justification.
2. Justify against the alternatives: standard library / platform API, ~30 lines of own code, or an existing dep already in the tree. A dep that saves less than it costs in audit surface doesn't go in.
3. Vet before adding: maintenance activity (commits/releases within the last year), download base, open CVEs, install scripts, transitive weight (`pnpm why` afterward).
4. Pin via the lockfile (committed, never hand-edited); version ranges follow the ecosystem default (caret) — the lockfile is the real pin.

## License allowlist

5. Allowed without question: `MIT`, `Apache-2.0`, `ISC`, `BSD-2-Clause`, `BSD-3-Clause`, `0BSD`, `BlueOak-1.0.0`, `CC0-1.0`, `Unlicense`, `Python-2.0`.
6. Anything else — notably any GPL/AGPL/LGPL, SSPL, BUSL, or "fair source" license — requires an explicit human decision recorded as an ADR before the dep enters the tree.
7. The allowlist is enforced in CI on production dependencies; the CI list and this list must match (same-commit rule).

## Audit cadence

8. Vulnerability audit runs **on every PR** (high+ severity blocks merge) and implicitly via the update tooling's security PRs.
9. A vulnerability with no upstream fix gets a documented decision: pin + mitigate, replace the dep, or accept-with-expiry (an ADR with a review date). Silent acceptance is not an option.
10. Quarterly: prune — remove deps no longer imported (`pnpm why` each suspect), and review anything held back by an accepted-risk ADR.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (deps job: `pnpm audit --prod --audit-level=high` + license allowlist check)
- Fallback if unenforceable: n/a — audit and license gates are CI-enforced; the justify-before-adding rule is enforced socially via the agent ask-first trigger and PR review.

## Bootstrap
- What new-project.sh injects for this standard: the PR workflow containing the deps job, and `.github/dependabot.yml` for the update side.
