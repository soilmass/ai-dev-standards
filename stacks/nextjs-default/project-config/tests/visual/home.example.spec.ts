// tests/visual/home.example.spec.ts — copied by new-project.sh.
// Governing doc: 04-build/testing-strategy.md (visual regression, nightly tier).
// Runs under the Playwright `visual` project (playwright.config.ts).
//
// Baseline workflow: baselines are created/updated LOCALLY, on purpose —
//   pnpm exec playwright test --project=visual --update-snapshots
// review the generated home.png like any diff, then commit it. CI only COMPARES
// against the committed baseline; it never regenerates one. A missing baseline
// fails the run rather than silently passing.

import { expect, test } from '@playwright/test';

test('home page matches visual baseline', async ({ page }) => {
  // EXAMPLE — '/' and 'home.png' are a placeholder route/baseline, not a contract;
  // rename per the page under test and point at your real landing route.
  await page.goto('/');
  await expect(page).toHaveScreenshot('home.png');
});
