<!-- stacks/nextjs-default/CLAUDE.partial.md — appended to the project CLAUDE.md by new-project.sh -->

## Stack rules — nextjs-default

This project runs the **nextjs-default** preset: Next.js (App Router) + TypeScript strict + Biome + Vitest/Testing Library/MSW + Playwright + Zod + Drizzle + Better Auth + pnpm, deployed on Vercel. Rationale per tool: `<STANDARDS_PATH>/stacks/nextjs-default/stack-decisions.md`.

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

1. **Install deps:** the bootstrap already injected a complete `package.json` (deps + scripts pre-declared) and `tsconfig.json` (strict + `noUncheckedIndexedAccess`, `@/*` paths). Set `name` in `package.json`, then `pnpm install`. *Why these versions:* TS is pinned to `^5` (toolchain peers reject 6); `zod@^4` + `drizzle-orm@^0.45.2` are Better Auth 1.6.x peers — keep them in step (ADR-S09/S11). The injected `package.json` is the single source of dep truth; don't hand-add what's already there.
2. **App skeleton:** the preset ships the configs, not the Next.js `app/` tree, so the dir is non-empty — do **not** run `create-next-app` in place (it refuses a non-empty dir). Either write `app/layout.tsx` + `app/page.tsx` yourself (a Server Component page is a few lines), or run `pnpm create next-app@latest` in a throwaway dir and copy its `app/` + `public/` + `next-env.d.ts` over (keep the injected `next.config.ts`, `tsconfig.json`, `package.json`). `.env.example` is injected — copy it to `.env.local` and fill real values.
3. **gitleaks binary** (not an npm package): `brew install gitleaks` or download from `github.com/gitleaks/gitleaks/releases` — the pre-commit hook fails closed without it.
4. **Hooks:** `pnpm exec husky init` (the bootstrap already placed `pre-commit` and `commit-msg` in `.husky/`); verify with a test commit on a branch.
5. **Visual baselines:** the test scaffolding is already injected — `tests/setup.ts` (jest-dom matchers + MSW server lifecycle), `tests/msw/` (server + contract-mirroring handlers), and example `tests/unit/`, `tests/e2e/`, `tests/visual/` tests. Adapt the examples to your app, then generate visual baselines locally (`pnpm exec playwright test --project=visual --update-snapshots`), review the PNGs, and commit them. CI never regenerates baselines.
6. **Database (do this before auth — auth generation needs a reachable DB):** start the local database with `docker compose up -d` (the injected `docker-compose.yml`) and point `DATABASE_URL` in `.env.local` at it. `db/schema.ts` (schema starter) and `lib/db.ts` (the lazy, server-only Drizzle client) are injected — adapt the schema, then `pnpm exec drizzle-kit generate` for the migration and `pnpm db:migrate` to apply it (optionally `pnpm db:seed`). `drizzle.config.ts` (injected) pins migrations to `./drizzle` — the CI guard watches that path. Add typed query functions bound to `getDb()` (keep data access in `lib/`, not components).
7. **Auth schema:** with `DATABASE_URL` set and the DB running (step 6), generate Better Auth's four tables (`user`/`session`/`account`/`verification`) from your `lib/auth.ts` with `pnpm dlx @better-auth/cli generate`, put them in `db/auth-schema.ts`, and **reconcile column names to snake_case** (data-modeling rule 1 — Better Auth's generator defaults to camelCase columns). Re-export them from `db/schema.ts` (`export * from './auth-schema'`) so drizzle-kit sees one schema, and make your domain tables' `userId` a real FK to `user.id`.
8. **Env validation at boot:** `instrumentation.ts` (injected) calls `serverEnv()` guarded on `NEXT_RUNTIME === 'nodejs'` so startup fails on bad config. **Call `serverEnv()` (and construct DB/auth clients) inside handlers / the request path, never at module top-level** — `next build` evaluates route modules, so a module-scope `serverEnv()` throws at build (env absent). `env.schema.ts` itself is import-safe; the discipline is on callers. Client code imports `clientEnv` only. `next.config.ts` (injected) sets `serverExternalPackages` for Better Auth + `pg`.
9. **After first push:** set branch protection per `<STANDARDS_PATH>/05-verification/ci-pipeline.md` (Bootstrap section) — all PR jobs as required checks (or run `bash scripts/setup-branch-protection.sh`).

### Stack-specific rules

1. **pnpm only.** Never npm/yarn; never edit `pnpm-lock.yaml` by hand.
2. **TypeScript strict stays strict.** No `any` (Biome errors), no `!` non-null assertions, no loosening `tsconfig.json` to make an error go away.
3. **Auth is Better Auth, with defense-in-depth.** Session checks happen in the route handler / server component (`auth.api.getSession(...)`) — **never in middleware alone** (CVE-2025-29927; see agent-operating-rules guardrail 3). Keep Next.js on a patched version.
4. **Database via Drizzle.** Schema lives in `db/schema.ts`; every change ships as a generated migration (`drizzle-kit generate`) that is reviewed in the PR. **Never `drizzle-kit push` against production** — prototyping only.
5. **Validation at the boundary with Zod.** Every Server Action, route handler, and form parses its input with a Zod schema; types are inferred from the schema (`z.infer`), shared front↔back — never duplicated by hand.
6. **Env vars only through `env.schema.ts`** (boot-validated). `process.env` reads anywhere else are a review violation. Server code calls `serverEnv()` **inside handlers/the request path, never at module top-level** (a module-scope call throws at `next build`); client code imports `clientEnv` (NEXT_PUBLIC_ only, read as literal property accesses — never loop over them). Importing `serverEnv` from a client component is a review violation: the values are undefined in the browser by design.
7. **Server Components by default; `'use client'` only when needed** (state, effects, browser APIs). Keep data fetching on the server.
8. **Testing split (Vitest cannot render async Server Components):** unit-test Server Actions, Zod schemas, hooks, and synchronous components with Vitest + Testing Library (MSW for network); cover async Server Components and full user flows with Playwright.
9. **Hooks are sacred:** pre-commit (lint-staged + gitleaks) and commit-msg (commitlint) run on every commit; do not bypass with `--no-verify`.
10. **Deployment is Vercel**, preview deploy per PR. If a feature needs WebSockets, cron, or long-running jobs, raise the three-box question (see `<STANDARDS_PATH>/00-governance/pinned-decisions.md`) rather than contorting it into serverless.
