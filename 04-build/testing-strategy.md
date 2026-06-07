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

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (test job with coverage gate) and stacks/nextjs-default/ci/nightly.yml (full E2E + visual regression)
- Fallback if unenforceable: n/a — suite presence and coverage are CI-enforced; assertion quality is covered by the self-review checklist's standing items.

## Bootstrap
- What new-project.sh injects for this standard: the CI workflows (`pr.yml`, `nightly.yml`) into `.github/workflows/`, which wire the per-PR coverage gate and the nightly E2E + visual tiers.
