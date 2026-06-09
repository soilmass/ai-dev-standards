# Testing Strategy

What gets tested, where, and how much. The shape is a pyramid: many fast unit/component tests, a thin integration band, and a deliberately small E2E crown. The stack preset names the runners; these rules don't change when the tools do.

## The pyramid

| Tier | Scope | Runs |
|---|---|---|
| Unit | Pure logic: validation schemas, server actions, utilities, hooks | Every PR (fast, parallel) |
| Component | Rendered components via user-facing queries (role/label), network mocked at the boundary | Every PR |
| Integration | Module seams: data access against a scratch DB, API handlers end-to-end in-process | Every PR |
| E2E | Real browser, real app, critical user journeys | Nightly + pre-deploy |

## Required per-PR vs per-release

- **Every PR:** unit + component + integration suites green, with the coverage gate (below). Accessibility unit checks run in this tier (see `05-verification/a11y-perf-gates.md`).
- **Nightly / pre-deploy:** full E2E suite + visual regression (see `05-verification/ci-pipeline.md`). A production deploy never skips the pre-deploy run.

## What each tier must cover

The pyramid says where a test *can* live; this says what each tier *owes*. Coverage percentage is a floor against erosion (below); this is the qualitative obligation that the percentage can't express — a suite can hit 70% and still never test a single deny path.

| Tier | Owes coverage of |
|---|---|
| Unit | Every branch of business/validation logic; the edge cases the logic implies (empty, null/undefined, zero, boundary, duplicate); **both sides of every decision** — a guard tested only on its allow path is half-tested. |
| Component | Each component's distinct states — loading, empty, error, populated — and its keyboard/ARIA interactions (the a11y checks of `05-verification/a11y-perf-gates.md`), not just the happy render. |
| Integration | Every data-access path against a scratch DB, and every API handler's **success + auth-failure + validation-failure** responses — the seam is where the authorization decision and the error envelope (`03-design/api-contract-design.md`) are actually proven. |
| E2E | Every revenue-critical journey end-to-end (the crown below), each exercised once as the real user flows it. |

Two obligations cut across the tiers:

- **Authorization is tested at both verdicts.** Every permission/role/ownership check has a test proving the allowed actor succeeds *and* the forbidden actor is refused, at the tier where the check lives (`_spines/security-privacy.md`). An authz check with only a positive test is the most expensive untested line in the codebase.
- **Coverage follows risk, not lines.** Security-relevant code — authorization, input parsing at the boundary, money/credits, file handling — earns explicit allow-and-deny and malformed-input tests regardless of what the coverage number already says; low-risk glue does not need tests written to chase the percentage. The threat model's mitigations (`03-design/threat-modeling.md`) each map to a test that would fail if the mitigation were removed.

## The E2E-scope rule

Keep the E2E suite at **≈20–30 tests covering revenue-critical paths only** — sign-up/sign-in, the core value loop, checkout/payment, anything whose breakage is an incident. E2E tests are the most expensive to run and maintain; breadth belongs in the lower tiers. A new E2E test must displace a marginal one or justify growing the suite.

## Coverage philosophy

- Coverage is **necessary but insufficient**: a low number proves under-testing, a high number proves nothing about assertion quality. Never write tests whose only purpose is moving the number.
- The CI coverage gate is a floor against erosion, not a target to game. Review assertions, not percentages.
- Test behavior, not implementation: a refactor that preserves behavior should not break tests.

## Test-runner limitation (guardrail)

**Vitest cannot render async Server Components** (React's async component support isn't stable in the test runner). Unit-test Server Actions, Zod schemas, and synchronous components with Vitest; cover async Server Components and full flows with Playwright instead.

## Hygiene

- Tests are deterministic: no real network (mock at the network boundary), no real clocks (fake timers), no order dependence.
- Visual-regression baselines are created and updated **locally, on purpose** (run the visual project with snapshot-update on, review the changed images like any diff, commit them); CI only compares against committed baselines, never regenerates them.
- A flaky test is a P1 against the suite: fix or quarantine-with-issue the same day; never retry-until-green as a policy.
- Test code is production code: same lint rules (relaxations only where the preset's config says so), same review bar.

## Standards basis

- **Test Pyramid** (Mike Cohn, *Succeeding with Agile*) — many fast unit tests, fewer integration, a thin UI/E2E crown: the shape of the tiers table and the E2E-scope rule.
- **Testing Trophy** (Kent C. Dodds, https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications) — weights the integration band heavily ("write tests, not too many, mostly integration") and adds **static analysis** as the base layer; grounds the per-PR integration emphasis and the lint-as-first-tier posture (static gate is the type-checker + linter, see `coding-standards.md`).
- **Google test sizes** (small/medium/large, *Software Engineering at Google*) — classifies tests by resource scope and determinism rather than position; the basis for the "deterministic: no real network, no real clocks, no order dependence" hygiene rule (small tests forbid network/disk/sleep).
- **Coverage as a floor, not a target** — Goodhart's law applied to metrics; coverage is necessary-not-sufficient. Aligned in the coverage-philosophy section: review assertions, gate against erosion.
- **Test behavior, not implementation** — the refactor-resilience principle (Testing Library guiding principle: "the more your tests resemble the way your software is used, the more confidence they give you").

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (test job with coverage gate) and stacks/nextjs-default/ci/nightly.yml (full E2E + visual regression)
- Fallback if unenforceable: n/a — suite presence and coverage are CI-enforced; assertion quality is covered by the self-review checklist's standing items.

## Bootstrap
- What new-project.sh injects for this standard: the CI workflows (`pr.yml`, `nightly.yml`) into `.github/workflows/`, which wire the per-PR coverage gate and the nightly E2E + visual tiers.
