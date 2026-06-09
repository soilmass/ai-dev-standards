// playwright.config.ts — copied from the preset's project-config/ by new-project.sh.
// Three project families:
//   e2e        — the ≈20–30 revenue-critical-path tests (04-build/testing-strategy.md)
//   smoke      — the functional-verification covenant (_spines/functional-verification.md):
//                run against the DEPLOYED/SERVED artifact (PLAYWRIGHT_BASE_URL, e.g. a PR
//                preview URL) to prove it boots, serves every declared route, has ZERO
//                console errors on load, and a primary flow reaches its expected outcome —
//                distinct from "tests pass". CI runs it against the preview deploy
//                (ci/pr.yml, job: smoke) before promotion.
//   visual-*   — screenshot comparisons against committed baselines (nightly CI),
//                one project PER VIEWPORT so a layout is verified at multiple widths,
//                not one (03-design/responsive-layout-discipline.md). The widths are
//                the responsive breakpoint set named below.
// Baseline workflow: create/update baselines LOCALLY with
//   pnpm exec playwright test --grep-invert e2e --update-snapshots
// (or target one width: --project=visual-768). Playwright suffixes each baseline
// PNG with the project name, so the same spec yields home-visual-320.png …
// home-visual-1280.png — review the changed PNGs like any diff, commit them.
// CI never regenerates. The nightly visual job runs every visual-* project.

import { defineConfig, devices } from '@playwright/test';

// VIEWPORT SET — the responsive breakpoint widths every visual baseline is shot at.
// Calibrated knob CAL-C15 (00-governance/calibration.md); the breakpoint ORDER and
// the requirement to verify at more than one width are the RULE
// (03-design/responsive-layout-discipline.md), these concrete widths are the CHOICE.
// 320 = smallest mainstream phone; 768 = tablet / mobile→tablet boundary;
// 1024 = tablet-landscape / small-laptop; 1280 = desktop. Heights are tall enough
// to capture above-the-fold without forcing full-page scroll noise.
const VISUAL_VIEWPORTS = [
  { name: 'visual-320', width: 320, height: 640 },
  { name: 'visual-768', width: 768, height: 1024 },
  { name: 'visual-1024', width: 1024, height: 768 },
  { name: 'visual-1280', width: 1280, height: 800 },
] as const;

// Console-error budget for the functional-verification smoke covenant
// (_spines/functional-verification.md). Calibrated knob CAL-F02
// (00-governance/calibration.md): a route that logs a console error on load is
// shipping a broken artifact — the budget is ZERO, never raised. The smoke specs
// in tests/smoke/ import this; the CI smoke job pins the same 0 in its env, so the
// doc↔config pair is drift-checked. A real third-party-script noise source is
// silenced at its source (or stubbed), not by widening this budget.
export const SMOKE_MAX_CONSOLE_ERRORS = 0;

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI, // a stray test.only must not shrink the suite in CI
  retries: 0, // flake is fixed, not retried (04-build/testing-strategy.md hygiene)
  reporter: process.env.CI ? [['html', { open: 'never' }], ['github']] : 'list',
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  expect: {
    toHaveScreenshot: {
      maxDiffPixelRatio: 0.01, // 1% drift budget; tighten per page as it stabilizes
    },
  },
  // Only boot a local production server when we're testing a LOCAL target. When
  // PLAYWRIGHT_BASE_URL points at an already-deployed surface (the smoke job runs
  // against the PR preview, ci/pr.yml), there is nothing to start — and starting
  // `pnpm start` with no local build would fail. So skip webServer for a remote base.
  webServer: process.env.PLAYWRIGHT_BASE_URL
    ? undefined
    : {
        command: 'pnpm start', // production build is built by the CI step before this
        url: 'http://localhost:3000',
        reuseExistingServer: !process.env.CI,
        timeout: 120_000,
      },
  projects: [
    {
      name: 'e2e',
      testDir: './tests/e2e',
      use: { ...devices['Desktop Chrome'] },
    },
    // The functional-verification smoke covenant. Specs in tests/smoke/ assert the
    // BUILT/DEPLOYED artifact actually works: boots, serves every declared route
    // (the smoke route set), zero console errors on load, a primary flow reaches
    // its expected outcome. Point baseURL at the deployed surface
    // (PLAYWRIGHT_BASE_URL = the PR preview URL) so this verifies the artifact,
    // not a local re-run of the test suite. See _spines/functional-verification.md.
    {
      name: 'smoke',
      testDir: './tests/smoke',
      use: { ...devices['Desktop Chrome'] },
    },
    // One visual project per breakpoint width: the same visual specs run at every
    // viewport, each producing its own width-suffixed baseline. This is the
    // mechanical enforcement of the multi-viewport rule — a layout that only holds
    // at desktop fails the 320/768/1024 baselines it can no longer match.
    ...VISUAL_VIEWPORTS.map(({ name, width, height }) => ({
      name,
      testDir: './tests/visual',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width, height },
      },
    })),
  ],
});
