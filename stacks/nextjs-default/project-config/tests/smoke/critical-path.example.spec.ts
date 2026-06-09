// tests/smoke/critical-path.example.spec.ts — copied by new-project.sh.
// Governing doc: _spines/functional-verification.md (the cross-cutting spine).
// Runs under the Playwright `smoke` project (playwright.config.ts), against the
// DEPLOYED/SERVED artifact (PLAYWRIGHT_BASE_URL — a PR preview URL in CI, see
// ci/pr.yml job: smoke). This proves the built thing actually WORKS, which is
// distinct from "the test suite passes": it boots, serves every declared route,
// resolves its declared endpoints, logs zero console errors on load, and a
// primary flow reaches its EXPECTED OUTCOME (not merely "no 500").
//
// Adapt the route list and the primary-flow assertions to your app; do NOT change
// the app to match an example string. Keep this lean — it is a covenant on the
// critical path, not a second E2E suite (let the ~20–30 e2e tests own breadth).

import { expect, test } from '@playwright/test';
import { SMOKE_MAX_CONSOLE_ERRORS as CONFIG_BUDGET } from '../../playwright.config';

// The zero-tolerance console-error budget (CAL-F02). The config constant is the
// source of truth; CI pins the identical value in its env (ci/pr.yml job: smoke)
// so the doc↔config pair is drift-checked. Never set this above 0.
const SMOKE_MAX_CONSOLE_ERRORS = process.env.SMOKE_MAX_CONSOLE_ERRORS
  ? Number(process.env.SMOKE_MAX_CONSOLE_ERRORS)
  : CONFIG_BUDGET;

// The smoke route set: the routes whose existence is part of the feature's
// acceptance criteria (02-product/acceptance-criteria.md names the full page set).
// EVERY one must boot clean — this is the build-health + endpoint-resolution check.
// Replace with your real declared routes; '/' is the only one assumed to exist.
const SMOKE_ROUTES = ['/'] as const;

// Attach a console + pageerror listener that records every error the artifact logs
// while loading. Returns the collected messages; assert it is empty against the
// zero-tolerance budget (CAL-G01).
function captureConsoleErrors(page: import('@playwright/test').Page): string[] {
  const errors: string[] = [];
  page.on('console', (msg) => {
    if (msg.type() === 'error') errors.push(`console.error: ${msg.text()}`);
  });
  page.on('pageerror', (err) => errors.push(`pageerror: ${err.message}`));
  return errors;
}

for (const route of SMOKE_ROUTES) {
  test(`smoke: ${route} boots, resolves, and loads with zero console errors`, async ({ page }) => {
    const errors = captureConsoleErrors(page);

    // Build health + endpoint resolution: the route must SERVE (2xx/3xx), not 4xx/5xx.
    const response = await page.goto(route, { waitUntil: 'networkidle' });
    expect(response, `no response for ${route}`).not.toBeNull();
    expect(response!.status(), `${route} did not serve`).toBeLessThan(400);

    // The page actually rendered a document, not a blank/error shell.
    await expect(page).toHaveTitle(/.+/);

    // Zero console errors on load — the named failure mode this spine owns,
    // made provably testable. Budget is CAL-F02 (0), pinned in the config.
    expect(
      errors.length,
      `${route} logged console error(s):\n${errors.join('\n')}`,
    ).toBeLessThanOrEqual(SMOKE_MAX_CONSOLE_ERRORS);
  });
}

test('smoke: primary flow reaches its expected outcome', async ({ page }) => {
  const errors = captureConsoleErrors(page);

  await page.goto('/', { waitUntil: 'networkidle' });

  // Prove the EXPECTED OUTCOME, not just "no 500". EXAMPLE: the primary CTA leads
  // somewhere that actually renders the next step of the flow. Replace the CTA
  // name and the outcome assertion with your real critical path (sign-up, the
  // core loop, checkout) — assert what the user should SEE on success.
  const cta = page.getByRole('link', { name: /get started|sign in/i });
  await expect(cta, 'primary CTA missing on the home page').toBeVisible();
  await cta.click();

  // The destination resolved and rendered its own content (not an error boundary).
  await expect(page).toHaveURL(/.+/);
  await expect(page.getByRole('heading')).toBeVisible();

  expect(
    errors.length,
    `primary flow logged console error(s):\n${errors.join('\n')}`,
  ).toBeLessThanOrEqual(SMOKE_MAX_CONSOLE_ERRORS);
});
