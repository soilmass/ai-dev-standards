// tests/msw/handlers.ts — copied from the preset's project-config/ by new-project.sh.
// Governing doc: 04-build/testing-strategy.md (mock at the network boundary).
//
// Handlers MUST mirror the real API contract (03-design/api-contract-design.md):
// same paths, same status codes, same response shapes. A handler that drifts from
// the contract makes a green test a lie. When the contract changes, change the
// handler in the same PR. Per-test overrides go through server.use(...) in the
// test, then are dropped by the afterEach reset in tests/setup.ts.

import { HttpResponse, http } from 'msw';

export const handlers = [
  // Example: replace with handlers that match your real contract.
  http.get('/api/users/:id', ({ params }) => {
    return HttpResponse.json({
      id: params.id,
      email: 'ada@example.com',
      created_at: '2026-01-01T00:00:00.000Z',
    });
  }),
];
