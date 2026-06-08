import 'server-only';

// lib/db.ts — the Prisma client (server-only). Copied from the preset's
// project-config/ by new-project.sh. The standard Prisma singleton, demonstrating
// the suite's rules:
//   - `server-only` so it can never be bundled into a client component;
//   - a global singleton so dev hot-reload doesn't exhaust the connection pool
//     (Prisma's documented Next.js pattern) — and so importing the module is cheap;
//   - env read through the boot-validated schema (`serverEnv()`), never raw
//     process.env (CLAUDE.md stack rule 6 / 04-build/secrets-config.md). Calling
//     serverEnv() lazily (inside the factory) keeps module import side-effect-free,
//     so `next build`'s module evaluation never throws on absent env.
// Run `prisma generate` (wired as postinstall) so `@prisma/client` is typed.

import { PrismaClient } from '@prisma/client';
import { serverEnv } from '@/env.schema';

const globalForPrisma = globalThis as unknown as { prisma?: PrismaClient };

export function getDb(): PrismaClient {
  if (!globalForPrisma.prisma) {
    globalForPrisma.prisma = new PrismaClient({
      datasourceUrl: serverEnv().DATABASE_URL,
    });
  }
  return globalForPrisma.prisma;
}
