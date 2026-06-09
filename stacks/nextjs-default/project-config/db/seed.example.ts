// db/seed.ts — local seed data (04-build/developer-experience.md). Idempotent:
// safe to run repeatedly. NEVER run against production (it writes rows).
// Usage: `docker compose up -d` → `pnpm db:migrate` → `pnpm db:seed`.

import { getDb } from '@/lib/db';
import { users } from '@/db/schema';

async function seed() {
  const db = getDb();
  // onConflictDoNothing keeps the seed idempotent (re-running adds no duplicates).
  await db
    .insert(users)
    .values([{ email: 'demo@example.com' }, { email: 'alice@example.com' }])
    .onConflictDoNothing({ target: users.email });

  const count = (await db.select().from(users)).length;
  console.warn(`seed complete — ${count} users`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
