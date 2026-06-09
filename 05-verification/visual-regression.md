# Visual Regression

A passing E2E suite proves the app *works*; it says almost nothing about whether it still *looks right*. A button that drifts off-screen, a layout that collapses at a breakpoint, a contrast change that swallows a CTA — all of these pass every assertion and ship a broken-looking page. This doc owns the visual-regression discipline: screenshotting customer-facing surfaces and failing the build when pixels change unexpectedly. The runner-hygiene rule for baselines (created locally, never by CI) lives in `04-build/testing-strategy.md`; this doc owns *what to shoot, how to keep it stable, and how to read a diff* — it does not restate that rule.

## What to cover

1. **Shoot customer-facing surfaces, not every component.** The visual suite guards what a user sees on the pages that matter — the marketing/landing surface, the core value screens, the conversion and checkout flow, the auth screens. It is not a per-component screenshot zoo; that breadth belongs in the component tier (`04-build/testing-strategy.md`), where rendered states are asserted by role and label, not by pixels.
2. **Capture the states and CTAs that carry the experience**, not just the default render of each page. A surface's distinct meaningful states — empty, populated, error, the primary call-to-action in its resting and active form — each earn a baseline where their *appearance* is load-bearing. A state whose only difference is text content the component tier already asserts does not need a pixel baseline.
3. **A new visual baseline is a deliberate addition, not a reflex.** Every committed baseline is a fixture the team maintains forever; add one when a surface's look is worth defending, retire one when the surface is gone. Coverage here follows visual risk — the pages whose breakage costs trust or revenue — the same way test coverage follows risk in `04-build/testing-strategy.md`.

## Baselines are reviewed like code

4. **Baselines are committed artifacts and reviewed like any diff.** The reference images live in the repo next to the tests; a change to a baseline is a change to the expected appearance of the product and goes through review on its own merits, exactly like a code change.
5. **Baselines are regenerated locally, on purpose — never by CI.** Updating a baseline is an explicit author action: run the visual project with snapshot-update on, inspect each changed image, and commit the ones that reflect intended changes (`04-build/testing-strategy.md`). CI only ever *compares* against committed baselines; a pipeline that regenerates baselines can never fail, because it has redefined "correct" to mean "whatever rendered today."
6. **An updated baseline must be justified by an intended change in the same change set.** A reviewer should be able to point to the design or code change that explains every modified reference image. A baseline that moved with no corresponding intent is the regression being smuggled in as the new normal — reject it.

## Reading a visual diff

7. **Every failure is triaged as intended change vs regression** before anything is committed. The pipeline surfaces the three-way comparison — expected, actual, and the highlighted diff — for each failure; the author opens it and decides which it is. There is no third option of "rerun until it passes."
8. **An intended change updates the baseline; a regression is fixed in the code.** If the new appearance is correct, regenerate that baseline locally (rule 5) and commit it with the change that caused it. If it is wrong, the diff just caught a real bug — fix the code, leave the baseline alone.
9. **A diff that is neither — random, unstable, different on every run — is a flakiness defect, not a result.** Do not paper over it with a wider tolerance or a retry; treat it as a determinism bug in the harness (next section) and fix the source of the nondeterminism.

## Flakiness control

10. **Pin everything that can render differently between two otherwise-identical runs.** Fonts are bundled or waited-for (never a system fallback that varies by host), the viewport is fixed, animations and transitions are disabled or settled before capture, and rendering is made deterministic (stable system clock, fixed locale and timezone, seeded or stubbed dynamic content). A screenshot test is only meaningful if the same input produces the same pixels every time.
11. **Wait for the surface to be settled, not merely loaded.** Capture only after fonts, images, and async content have resolved and motion has stopped; a screenshot taken mid-paint compares two arbitrary moments and will flake. Stability of the captured frame is a precondition of the test, not a tuning afterthought.
12. **Allow a small, bounded drift tolerance — and keep it small.** A tiny per-page pixel-difference budget absorbs sub-perceptual rendering noise without masking real regressions; the budget is configured per page in the preset's visual project (`stacks/nextjs-default/project-config/playwright.config.example.ts`) and tightened as a surface stabilizes. The tolerance is a noise floor, never a substitute for fixing nondeterminism — widening it to make a flaky test pass is rule 9's defect in disguise.

## Visual tests complement E2E, they do not replace it

13. **Pixels and behavior answer different questions; you need both.** Visual regression proves the page still *looks* right; E2E acceptance (`04-build/testing-strategy.md`) proves the user can still *complete the journey*. A surface can be pixel-perfect and functionally broken, or behaviorally green and visually wrecked — neither suite covers the other's failure mode.
14. **Visual regression is a nightly / pre-deploy tier, not a per-PR gate.** Like the full E2E crown, it is too slow and environment-sensitive to run on every push; it runs nightly and before any production deploy (`05-verification/ci-pipeline.md`), and a production deploy never skips it.

## Standards basis

- **Visual / snapshot testing** — the established practice of capturing a rendered reference and asserting future renders match it, surfacing unintended appearance changes that functional assertions miss (the screenshot-comparison capability built into modern browser-automation runners such as Playwright and Cypress, and the broader image-snapshot-testing lineage). Basis for rules 1–8: shoot the surfaces that matter, commit and review the references, triage each diff as intent vs regression.
- **Deterministic rendering for stable screenshots** — the consensus reliability requirement that a pixel comparison is only valid if the rendered frame is reproducible: pinned fonts, fixed viewport, disabled animations, a frozen clock/locale, and a settled (not merely loaded) DOM, with a small image-difference tolerance to absorb sub-perceptual platform noise (the documented stabilization guidance for screenshot assertions in Playwright/Cypress and the image-snapshot tooling ecosystem). Basis for rules 9–12.
- **Test Pyramid** (Mike Cohn, *Succeeding with Agile*) and the **Testing Trophy** (Kent C. Dodds) — both place broad, slow, environment-sensitive UI checks at the narrow top, exercised sparingly; the basis for rules 1–2 (cover key surfaces, not every component) and rule 14 (a nightly tier, not a per-PR gate). The full pyramid and the complement-not-replace relationship to E2E (rule 13) are owned by `04-build/testing-strategy.md`.
- **Determinism in tests** (Google's small/medium/large test sizes, *Software Engineering at Google*: hermetic, repeatable tests forbid dependence on the network, real clocks, and ambient state) — the general principle that rules 10–11 specialize to pixel reproducibility, consistent with the determinism hygiene rule in `04-build/testing-strategy.md`.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/nightly.yml (visual-regression job: compares against committed baselines with `--update-snapshots=none`, never regenerates) + stacks/nextjs-default/project-config/playwright.config.example.ts (the `visual` project and its per-page `maxDiffPixelRatio` drift tolerance)
- Fallback if unenforceable: n/a — the nightly visual-regression job compares against committed baselines and fails on out-of-tolerance pixel drift; baseline-review judgment rides the standing self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the nightly visual-regression job is injected by `04-build/testing-strategy.md`'s CI workflows, and the `visual` Playwright project with its drift tolerance is injected by the playwright config those workflows run).
