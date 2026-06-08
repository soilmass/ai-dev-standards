// playwright.config.ts — copied from the preset's project-config/ by new-project.sh.
// Two projects:
//   e2e    — the ≈20–30 revenue-critical-path tests (04-build/testing-strategy.md)
//   visual — screenshot comparisons against committed baselines (nightly CI)
// Baseline workflow: create/update baselines LOCALLY with
//   pnpm exec playwright test --project=visual --update-snapshots
// review the changed PNGs like any diff, commit them. CI never regenerates.

import { defineConfig, devices } from '@playwright/test';

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
  webServer: {
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
    {
      name: 'visual',
      testDir: './tests/visual',
      use: { ...devices['Desktop Chrome'] },
      expect: {
        toHaveScreenshot: {
          maxDiffPixelRatio: 0.01, // 1% drift budget; tighten per page as it stabilizes
        },
      },
    },
  ],
});
