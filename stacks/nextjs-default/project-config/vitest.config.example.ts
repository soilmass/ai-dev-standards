// vitest.config.ts — copied from the preset's project-config/ by new-project.sh.
// This is what makes the CI "coverage gate" real: thresholds below fail
// `vitest run --coverage` when crossed (05-verification/ci-pipeline.md).
// The thresholds are an EROSION FLOOR, not a target — raise them as real
// coverage grows; lowering one is a reviewable diff with a stated reason
// (04-build/testing-strategy.md).

import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';
import { defineConfig } from 'vitest/config';

export default defineConfig({
  plugins: [react(), tsconfigPaths()],
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'], // jest-dom matchers + MSW server lifecycle
    include: ['**/*.test.{ts,tsx}'],
    exclude: ['node_modules', '.next', 'tests/e2e/**', 'tests/visual/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'lcov'],
      // Scope the UNIT-coverage denominator to unit-testable logic. The testing
      // split (04-build/testing-strategy.md) routes Server Components, the live DB
      // client, and the auth seam to Playwright/integration — counting app/** or
      // db/** here makes the threshold unreachable-by-design for a correctly-split
      // project. Surfaced by the first project; see flow-back FB-02. Add client-only
      // components/** here once you have unit-tested client components.
      include: ['lib/**'],
      exclude: [
        '**/*.test.*',
        '**/*.d.ts',
        '**/generated/**',
        'lib/db.ts', // live DB client — integration-tested, not units
        'lib/session.ts', // auth seam — Playwright/integration once auth is wired
        'lib/*-repo.ts', // interfaces / ports — no executable lines
      ],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70,
      },
    },
  },
});
