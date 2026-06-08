import 'server-only';

// lib/db.ts — the live Drizzle client (server-only). Copied from the preset's
// project-config/ by new-project.sh; the boilerplate every Drizzle+Postgres app
// needs, demonstrating the suite's own rules:
//   - `server-only` so it can never be bundled into a client component;
//   - the pool is built LAZILY so importing this module opens no connection at
//     build time (next build evaluates modules) — construct DB/auth clients in the
//     request path, never at module top level (CLAUDE.partial rule 6);
//   - env read through the boot-validated schema (`serverEnv()`), never raw
//     process.env (CLAUDE.md stack rule 6 / 04-build/secrets-config.md).
// Add your typed query functions alongside (or in lib/<feature>-queries.ts) and
// bind them to `getDb()`; keep app data-access here, not in components.

import { drizzle } from 'drizzle-orm/node-postgres';
import { Pool } from 'pg';
import * as schema from '@/db/schema';
import { serverEnv } from '@/env.schema';

let pool: Pool | undefined;

export function getDb() {
  if (!pool) {
    pool = new Pool({ connectionString: serverEnv().DATABASE_URL });
  }
  return drizzle(pool, { schema });
}
