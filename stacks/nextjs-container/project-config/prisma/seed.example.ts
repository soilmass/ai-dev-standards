// prisma/seed.ts — local seed data (04-build/developer-experience.md). Idempotent:
// safe to run repeatedly. NEVER run against production (it writes rows).
// Usage: `docker compose up -d` → `pnpm db:migrate:dev` → `pnpm db:seed`.

import { getDb } from '@/lib/db';

const SEED_ID = '00000000-0000-7000-8000-000000000001';

async function seed() {
  const db = getDb();
  // upsert keeps the seed idempotent (re-running adds no duplicates).
  await db.item.upsert({
    where: { id: SEED_ID },
    update: {},
    create: {
      id: SEED_ID,
      userId: 'seed-user',
      url: 'https://example.com',
      title: 'Demo item',
    },
  });

  const count = await db.item.count();
  console.warn(`seed complete — ${count} items`);
}

seed()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });
