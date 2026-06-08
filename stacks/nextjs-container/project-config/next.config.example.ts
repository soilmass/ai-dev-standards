// next.config.ts — copied from the preset's project-config/ by new-project.sh.
//
// serverExternalPackages: Better Auth pulls optional adapter deps (kysely SQLite
// dialects) that must NOT be webpack-bundled, and `pg` is a native driver — both
// run as native node modules on the server. Without this, `next build` fails with
// kysely import-resolution errors. (Surfaced by the first project wiring Better
// Auth; this is the preset's standing fix — see the library flow-back log FB-03.)
//
// Keep this list to genuinely server-only native/optional-dep packages; do not add
// app dependencies here.

import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  serverExternalPackages: ['better-auth', 'pg', '@prisma/client'],
  // Container preset: emit a self-contained server bundle so the Docker image
  // copies only .next/standalone + static assets, not all of node_modules.
  output: 'standalone',
};

export default nextConfig;
