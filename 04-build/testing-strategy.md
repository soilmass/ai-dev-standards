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

## Advanced techniques — reach for these by risk

The pyramid is the default; these are sharper tools for specific high-risk code, applied **by risk, not always-on**. Security- and money-critical paths (auth, payments, input parsing, access control) earn them; a CRUD form does not.

- **Property-based testing** — for code with a wide input space and a clear invariant (parsers, validators, serializers, money/permission math): assert the property holds over *generated* inputs instead of a few hand-picked examples; the runner shrinks any failure to a minimal case. Surfaces the edge case you didn't think to write.
- **Mutation testing** — the test for your tests: it mutates the code under test and fails if no test notices, measuring assertion quality the coverage % cannot. Run it on the modules that matter (core business logic), not the whole repo.
- **Consumer-driven contract testing** — when you own an API with separate consumers (or consume one): pin the request/response contract so a provider change that would break a consumer fails in CI, not in production. Complements `03-design/api-contract-design.md` and `03-design/api-evolution.md`.
- **Fuzzing** — for untrusted-input boundaries (parsers, file/upload handling, anything taking raw bytes): feed malformed/random input to surface crashes and security bugs no example test would. Ties to the threat model (`03-design/threat-modeling.md`).

## Test-runner limitation (guardrail)

**Vitest cannot render async Server Components** (React's async component support isn't stable in the test runner). Unit-test Server Actions, Zod schemas, and synchronous components with Vitest; cover async Server Components and full flows with Playwright instead.

## Hygiene

- Tests are deterministic: no real network (mock at the network boundary), no real clocks (fake timers), no order dependence.
- Visual-regression baselines are created and updated **locally, on purpose** (run the visual project with snapshot-update on, review the changed images like any diff, commit them); CI only compares against committed baselines, never regenerates them.
- A flaky test is a P1 against the suite: fix or quarantine-with-issue the same day; never retry-until-green as a policy.
- Test code is production code: same lint rules (relaxations only where the preset's config says so), same review bar.

## Failure-path coverage

The reliability spine makes every outbound dependency carry a timeout, bounded retry, circuit breaker, and a chosen degradation (`_spines/reliability.md` rules 1–3; the per-call contract is `04-build/third-party-integrations.md`). Those resilience controls are claims, and an untested claim is an unreliable one — so the failure path is a **named coverage obligation**, not an optional extra beyond the happy, auth, and validation paths. The integration tier is where it lands, because that seam is where the dependency wrapper, the fallback, and the degraded envelope actually execute together.

- **Four failure paths are asserted at the integration tier, each with its own test, for every wrapped dependency:**
  1. **Downstream timeout** — the dependency does not answer within the budget; assert the call is abandoned at the timeout (not left to hang) and the chosen response is served.
  2. **Circuit-breaker open** — with the breaker tripped, assert the request short-circuits to the *fallback/degraded* response immediately, rather than re-attempting the dead dependency.
  3. **Partial failure** — one dependency in a multi-call path fails while others succeed; assert the feature degrades only the affected slice (the page stays up, the unaffected data still renders) rather than failing whole.
  4. **Malformed / error response** — the dependency returns a 5xx, a 4xx, or a schema-violating body; assert it is treated as untrusted input (rejected at the boundary per `04-build/third-party-integrations.md` rule 10) and surfaced as the honest degraded outcome, never propagated raw.
- **Assert the user-visible outcome, not just the internal branch.** A failure-path test that only checks an error was caught proves nothing about what the user gets. Assert the *degraded result*: the fallback renders, the cached/stale value is served, the "temporarily unavailable" envelope returns its declared status — the behavior the degradation decision (`_spines/reliability.md` rule 1) actually promised.
- **The mock pattern: override the boundary mock to inject the fault.** These tests reuse the same network-boundary mock the happy path already uses (the hygiene rule forbids real network), but override it per case to raise a timeout, return an error status, or yield a malformed body — then assert the degraded outcome. No new infrastructure: the seam that the happy path mocks is the same seam the failure paths fault-inject.
- **Each is observable.** Per `_spines/reliability.md` rule 3, healthy-degraded is distinct from erroring; where the degraded path emits the "serving fallback / circuit open" signal, the test asserts that signal too, so the alerting story is proven alongside the user-facing one.

These are obligations the coverage percentage cannot express — a suite can hit its floor having tested only the path where every dependency answers correctly. The threat model's mitigations already earn a removal-detecting test (above); the reliability spine's degradation modes earn the same.

## Standards basis

- **Test Pyramid** (Mike Cohn, *Succeeding with Agile*) — many fast unit tests, fewer integration, a thin UI/E2E crown: the shape of the tiers table and the E2E-scope rule.
- **Testing Trophy** (Kent C. Dodds, https://kentcdodds.com/blog/the-testing-trophy-and-testing-classifications) — weights the integration band heavily ("write tests, not too many, mostly integration") and adds **static analysis** as the base layer; grounds the per-PR integration emphasis and the lint-as-first-tier posture (static gate is the type-checker + linter, see `04-build/coding-standards.md`).
- **Property-based testing** (QuickCheck lineage; Hypothesis, fast-check) — generate-and-shrink over invariants; the basis for the advanced property-testing technique. **Mutation testing** (Stryker, PIT — "who tests the tests") — assertion-quality measurement behind the mutation technique. **Consumer-driven contract testing** (Pact) — the provider/consumer contract guarantee. **Coverage-guided fuzzing** (AFL/libFuzzer lineage, OSS-Fuzz) — input-boundary crash/security discovery. Each is applied by risk, per the advanced-techniques section.
- **Fault injection / negative testing** — Michael Nygard, *Release It!* (the Stability patterns the failure-path tests verify are real: Timeout, Circuit Breaker, Fail Fast) and the ISTQB-defined **negative test case** (exercise invalid/error conditions, not just valid input): the basis for the failure-path-coverage section's four asserted paths and the mock-override fault-injection pattern. Resilience-engineering practice (fault injection as a first-class test, popularized by Netflix's Chaos Monkey lineage) is the same idea pushed to production; here it lives at the integration tier against a faulted boundary mock.
- **Google test sizes** (small/medium/large, *Software Engineering at Google*) — classifies tests by resource scope and determinism rather than position; the basis for the "deterministic: no real network, no real clocks, no order dependence" hygiene rule (small tests forbid network/disk/sleep).
- **Coverage as a floor, not a target** — Goodhart's law applied to metrics; coverage is necessary-not-sufficient. Aligned in the coverage-philosophy section: review assertions, gate against erosion.
- **Test behavior, not implementation** — the refactor-resilience principle (Testing Library guiding principle: "the more your tests resemble the way your software is used, the more confidence they give you").

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (test job with coverage gate) and stacks/nextjs-default/ci/nightly.yml (full E2E + visual regression)
- Fallback if unenforceable: n/a — suite presence and coverage are CI-enforced; assertion quality is covered by the self-review checklist's standing items.

## Bootstrap
- What new-project.sh injects for this standard: the CI workflows (`pr.yml`, `nightly.yml`) into `.github/workflows/`, which wire the per-PR coverage gate and the nightly E2E + visual tiers.
