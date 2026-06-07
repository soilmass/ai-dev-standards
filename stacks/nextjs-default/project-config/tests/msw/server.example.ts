// tests/msw/server.ts — copied from the preset's project-config/ by new-project.sh.
// Governing doc: 04-build/testing-strategy.md (mock at the network boundary).
// The Node-side MSW server used by Vitest. A single shared instance whose
// lifecycle (listen/resetHandlers/close) is owned by tests/setup.ts.

import { setupServer } from 'msw/node';
import { handlers } from './handlers';

export const server = setupServer(...handlers);
