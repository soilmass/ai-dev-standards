// tests/e2e/smoke.example.spec.ts — copied by new-project.sh.
// Governing doc: 04-build/testing-strategy.md (E2E tier: real browser, real app,
// revenue-critical paths only). Runs under the Playwright `e2e` project
// (playwright.config.ts). This is the minimal smoke check the home page is
// reachable, navigable, and clean of console errors — expand toward the
// ~20–30 critical-path budget, do not let breadth grow here.

import { expect, test } from '@playwright/test';

test('home page loads, primary CTA is visible, no console errors', async ({ page }) => {
  const consoleErrors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  const response = await page.goto('/');
  expect(response?.status()).toBeLessThan(400);

  await expect(page).toHaveTitle(/.+/);

  // Query by role like a user would (accessible name), not by CSS selector.
  await expect(page.getByRole('navigation')).toBeVisible();
  // EXAMPLE assertion — replace the CTA name regex with your real primary CTA;
  // adapt the example to your app, do not change the app to match this string.
  await expect(page.getByRole('link', { name: /get started|sign in/i })).toBeVisible();

  expect(consoleErrors).toEqual([]);
});
