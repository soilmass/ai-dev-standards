// drizzle.config.ts — copied from the preset's project-config/ by new-project.sh.
// `out` is pinned to ./drizzle so the CI migration-discipline guard's pathspec
// ('drizzle/**/*.sql' in pr.yml) is guaranteed to watch the right directory.
// If you ever move it, change BOTH in the same commit (root CLAUDE.md same-commit rule).

import { defineConfig } from 'drizzle-kit';

export default defineConfig({
  schema: './db/schema.ts',
  out: './drizzle',
  dialect: 'postgresql',
  dbCredentials: {
    // Read via the boot-validated schema, never raw process.env elsewhere
    // (04-build/secrets-config.md). drizzle-kit runs in Node, so direct read here is the boundary.
    url: process.env.DATABASE_URL ?? '',
  },
  strict: true, // prompt on destructive statements during generate
});
