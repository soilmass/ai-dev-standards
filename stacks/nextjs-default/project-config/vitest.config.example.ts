// vitest.config.ts — copied from the preset's project-config/ by new-project.sh.
// This is what makes the CI "coverage gate" real: thresholds below fail
// `vitest run --coverage` when crossed (05-verification/ci-pipeline.md).
// The thresholds are an EROSION FLOOR, not a target — raise them as real
// coverage grows; lowering one is a reviewable diff with a stated reason
// (04-build/testing-strategy.md).

import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import tsconfigPaths from 'vite-tsconfig-paths';

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
      include: ['app/**', 'components/**', 'lib/**', 'db/**'],
      exclude: ['**/*.test.*', '**/*.d.ts', '**/generated/**'],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 70,
        statements: 70,
      },
    },
  },
});
