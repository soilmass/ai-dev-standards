<!-- stacks/nextjs-default/CLAUDE.partial.md — appended to the project CLAUDE.md by new-project.sh -->

## Stack rules — nextjs-default

This project runs the **nextjs-default** preset: Next.js (App Router) + TypeScript strict + Biome + Vitest/Testing Library/MSW + Playwright + Zod + Drizzle + Better Auth + pnpm, deployed on Vercel. Rationale per tool: `stack-decisions.md` in the preset directory.

### Commands

| Action | Command |
|---|---|
| Install | `pnpm install` |
| Dev server | `pnpm dev` |
| Lint + format (check) | `pnpm exec biome ci .` |
| Lint + format (fix) | `pnpm exec biome check --write .` |
| Type check | `pnpm exec tsc --noEmit` |
| Unit/component tests | `pnpm exec vitest run` |
| E2E tests | `pnpm exec playwright test` |
| Build | `pnpm build` |
| New DB migration | `pnpm exec drizzle-kit generate` |
| Apply migrations | `pnpm exec drizzle-kit migrate` |

### Project setup after bootstrap

One-time wiring, in order (the bootstrap copies configs; this makes them executable):

1. **Scaffold the app** (if not already): `pnpm create next-app@latest . --typescript --app --no-eslint` (Biome replaces ESLint here; remove any generated ESLint config). In `tsconfig.json` ensure `"strict": true` and add `"noUncheckedIndexedAccess": true` (ADR-S03).
2. **Runtime deps:** `pnpm add zod drizzle-orm better-auth`
3. **Dev deps:** `pnpm add -D @biomejs/biome typescript@^5 tsx vitest @vitejs/plugin-react vite-tsconfig-paths @vitest/coverage-v8 jsdom @testing-library/react @testing-library/jest-dom @testing-library/user-event msw @playwright/test drizzle-kit husky lint-staged @commitlint/cli @commitlint/config-conventional` (TS pinned to 5.x — several toolchain peers don't accept 6 yet)
4. **gitleaks binary** (not an npm package): `brew install gitleaks` or download from `github.com/gitleaks/gitleaks/releases` — the pre-commit hook fails closed without it.
5. **Hooks:** `pnpm exec husky init` (the bootstrap already placed `pre-commit` and `commit-msg` in `.husky/`); verify with a test commit on a branch.
6. **Visual baselines:** the test scaffolding is already injected — `tests/setup.ts` (jest-dom matchers + MSW server lifecycle), `tests/msw/` (server + contract-mirroring handlers), and example `tests/unit/`, `tests/e2e/`, `tests/visual/` tests. Adapt the examples to your app, then generate visual baselines locally (`pnpm exec playwright test --project=visual --update-snapshots`), review the PNGs, and commit them. CI never regenerates baselines.
7. **Database:** `db/schema.ts` is already injected as a `users` starter (snake_case, UUID PK, `created_at`/`updated_at`, soft-delete noted as a per-table decision). Adapt it, set `DATABASE_URL` in `.env.local`, then `pnpm exec drizzle-kit generate` for the first migration. `drizzle.config.ts` (already injected) pins migrations to `./drizzle` — the CI guard watches that path.
8. **Env validation at boot:** `instrumentation.ts` is already injected and calls `serverEnv()` (guarded on `NEXT_RUNTIME === 'nodejs'`) so startup fails on bad config. If your own scaffold created an `instrumentation.ts`, merge the `serverEnv()` call into it. Client code imports `clientEnv` only.
9. **After first push:** set branch protection per `05-verification/ci-pipeline.md` (Bootstrap section) — all PR jobs as required checks.

### Stack-specific rules

1. **pnpm only.** Never npm/yarn; never edit `pnpm-lock.yaml` by hand.
2. **TypeScript strict stays strict.** No `any` (Biome errors), no `!` non-null assertions, no loosening `tsconfig.json` to make an error go away.
3. **Auth is Better Auth, with defense-in-depth.** Session checks happen in the route handler / server component (`auth.api.getSession(...)`) — **never in middleware alone** (CVE-2025-29927; see agent-operating-rules guardrail 3). Keep Next.js on a patched version.
4. **Database via Drizzle.** Schema lives in `db/schema.ts`; every change ships as a generated migration (`drizzle-kit generate`) that is reviewed in the PR. **Never `drizzle-kit push` against production** — prototyping only.
5. **Validation at the boundary with Zod.** Every Server Action, route handler, and form parses its input with a Zod schema; types are inferred from the schema (`z.infer`), shared front↔back — never duplicated by hand.
6. **Env vars only through `env.schema.ts`** (boot-validated). `process.env` reads anywhere else are a review violation. Server code calls `serverEnv()`; client code imports `clientEnv` (NEXT_PUBLIC_ only, read as literal property accesses — never loop over them). Importing `serverEnv` from a client component is a review violation: the values are undefined in the browser by design.
7. **Server Components by default; `'use client'` only when needed** (state, effects, browser APIs). Keep data fetching on the server.
8. **Testing split (Vitest cannot render async Server Components):** unit-test Server Actions, Zod schemas, hooks, and synchronous components with Vitest + Testing Library (MSW for network); cover async Server Components and full user flows with Playwright.
9. **Hooks are sacred:** pre-commit (lint-staged + gitleaks) and commit-msg (commitlint) run on every commit; do not bypass with `--no-verify`.
10. **Deployment is Vercel**, preview deploy per PR. If a feature needs WebSockets, cron, or long-running jobs, raise the three-box question (see `pinned-decisions.md`) rather than contorting it into serverless.
