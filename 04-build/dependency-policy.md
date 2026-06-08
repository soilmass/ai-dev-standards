# Dependency Policy

Every dependency is code you now own without having written. This doc governs how deps enter, stay in, and leave a project. Update *cadence* is the maintenance side — see `08-maintenance/dependency-updates.md`.

## Adding a dependency

1. **Adding/removing a dependency is an ask-first action for agents** (`00-governance/agent-operating-rules.md` §2). Humans add deps via a PR that states the justification.
2. Justify against the alternatives: standard library / platform API, ~30 lines of own code, or an existing dep already in the tree. A dep that saves less than it costs in audit surface doesn't go in.
3. Vet before adding: maintenance activity (commits/releases within the last year), download base, open CVEs, install scripts, transitive weight (check with the package manager's dependency-explain command afterward).
4. Pin via the lockfile (committed, never hand-edited); version ranges follow the ecosystem default (caret) — the lockfile is the real pin.

## License allowlist

5. Allowed without question: `MIT`, `Apache-2.0`, `ISC`, `BSD-2-Clause`, `BSD-3-Clause`, `0BSD`, `BlueOak-1.0.0`, `CC0-1.0`, `Unlicense`, `Python-2.0`.
6. Anything else — notably any GPL/AGPL/LGPL, SSPL, BUSL, or "fair source" license — requires an explicit human decision recorded as an ADR before the dep enters the tree.
7. The allowlist is enforced in CI on production dependencies; the CI list and this list must match (same-commit rule).

## Audit cadence

8. Vulnerability audit runs **on every PR** (high+ severity blocks merge) and implicitly via the update tooling's security PRs.
9. A vulnerability with no upstream fix gets a documented decision: pin + mitigate, replace the dep, or accept-with-expiry (an ADR with a review date). Silent acceptance is not an option.
10. Quarterly: prune — remove deps no longer imported (trace each suspect with the dependency-explain command), and review anything held back by an accepted-risk ADR.

## Build provenance

11. Released artifacts carry **build provenance** — a signed attestation of what built them, from which source commit, with which inputs. Generate it in CI (the platform's attestation step) so consumers can verify the artifact traces to this repo, not a tampered build. This is the producer side of the same supply-chain trust the audit/license gates enforce on the consumer side.

## Standards basis

- **SLSA v1.0 Build Track** (https://slsa.dev/spec/v1.0/levels) — Build L1 requires provenance describing the build; L2 adds a hosted, signed build; L3 adds isolation/non-falsifiability. Grounds the build-provenance rule (rule 11); provenance is expressed as **in-toto attestations**.
- **OpenSSF Scorecard** (https://scorecard.dev) — automated 0–10 security-health heuristics (Maintained, Vulnerabilities, Dangerous-Workflow, Pinned-Dependencies, Signed-Releases) for evaluating a dependency before adoption: the objective backbone of the rule 3 vetting checklist.
- **SPDX License List** (https://spdx.org/licenses/) — canonical machine-readable license short-identifiers; the allowlist (rules 5–6) and CI license check are expressed in SPDX IDs for unambiguous, language-neutral matching.
- **OWASP Dependency management / Vulnerable & Outdated Components** (OWASP Top 10 A06) — mandates inventorying components and continuously monitoring for known CVEs: grounds the per-PR audit gate (rule 8) and the documented-decision rule for unfixed vulns (rule 9).

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (deps job: `pnpm audit --prod --audit-level=high` + license allowlist check)
- Fallback if unenforceable: n/a — audit and license gates are CI-enforced; the justify-before-adding rule is enforced socially via the agent ask-first trigger and PR review.

## Bootstrap
- What new-project.sh injects for this standard: the PR workflow containing the deps job, and `.github/dependabot.yml` for the update side.
