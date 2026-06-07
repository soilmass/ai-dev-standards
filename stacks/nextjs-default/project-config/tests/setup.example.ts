// tests/setup.ts — copied from the preset's project-config/ by new-project.sh.
// Vitest global setup, wired via setupFiles in vitest.config.ts.
// Governing doc: 04-build/testing-strategy.md (hygiene: no real network, mock at
// the boundary). This file (a) registers jest-dom matchers for role/label-based
// assertions and (b) owns the MSW server lifecycle so every test runs against
// the same intercepted network, reset between tests for isolation.

import '@testing-library/jest-dom/vitest';
import { afterAll, afterEach, beforeAll } from 'vitest';
import { server } from './msw/server';

// Fail loudly on a request with no handler — an un-mocked request is a test bug,
// not a silent pass-through (testing-strategy.md: no real network).
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));

// Drop per-test handler overrides so tests cannot leak state into each other.
afterEach(() => server.resetHandlers());

afterAll(() => server.close());
