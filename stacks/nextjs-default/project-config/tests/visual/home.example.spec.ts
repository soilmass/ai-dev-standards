// tests/visual/home.example.spec.ts — copied by new-project.sh.
// Governing docs: 04-build/testing-strategy.md (visual regression, nightly tier)
//   + 03-design/responsive-layout-discipline.md (verify layout at multiple viewports).
// Runs under EVERY per-viewport `visual-*` project (playwright.config.ts), so this
// one spec produces a baseline at each breakpoint width — Playwright suffixes each
// PNG with the project name, e.g. home-visual-320.png … home-visual-1280.png.
//
// Baseline workflow: baselines are created/updated LOCALLY, on purpose —
//   pnpm exec playwright test --project=visual-320 --project=visual-768 \
//     --project=visual-1024 --project=visual-1280 --update-snapshots
// review each generated home-*.png like a diff, then commit them. CI only COMPARES
// against the committed baselines; it never regenerates one. A missing baseline
// fails the run rather than silently passing.

import { expect, test } from '@playwright/test';

test('home page matches visual baseline', async ({ page }) => {
  // EXAMPLE — '/' and 'home.png' are a placeholder route/baseline, not a contract;
  // rename per the page under test and point at your real landing route. The
  // viewport is set by the active visual-* project, so the same call captures the
  // page at each responsive breakpoint width.
  await page.goto('/');
  await expect(page).toHaveScreenshot('home.png');
});
