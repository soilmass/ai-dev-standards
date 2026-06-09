<!-- stacks/nextjs-container/CLAUDE.partial.md — appended to the project CLAUDE.md by new-project.sh -->

## Stack rules — nextjs-container

This project runs the **nextjs-container** preset: Next.js (App Router, `output: 'standalone'`) + TypeScript strict + Biome + Vitest/Testing Library/MSW + Playwright + Zod + **Prisma** + Better Auth + pnpm, shipped as a **container image to a container PaaS** (Railway/Fly/Render). It is the warm-Node deviation of `nextjs-default` (ORM and hosting differ; everything else is the same). Rationale per tool: `<STANDARDS_PATH>/stacks/nextjs-container/stack-decisions.md`.

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
| Generate Prisma client | `pnpm exec prisma generate` |
| New DB migration (dev) | `pnpm exec prisma migrate dev --name <change>` |
| Apply migrations (prod) | `pnpm exec prisma migrate deploy` |
| Build image | `docker build -t <name> .` |

### Project setup after bootstrap

One-time wiring, in order (the bootstrap copies configs; this makes them executable):

1. **Install deps:** the bootstrap injected a complete `package.json` (deps + scripts pre-declared, ORM = Prisma) and `tsconfig.json` (strict + `noUncheckedIndexedAccess`, `@/*` paths). Set `name` in `package.json`, then `pnpm install` — the `postinstall` runs `prisma generate` so `@prisma/client` is typed. *Why these versions:* TS `^5` (peers reject 6); `zod@^4` is a Better Auth 1.6.x peer; `prisma` (ADR-S09/S10). The injected `package.json` is the single source of dep truth.
2. **App skeleton:** the preset ships the configs, not the Next.js `app/` tree, so the dir is non-empty — do **not** run `create-next-app` in place. Write `app/layout.tsx` + `app/page.tsx` yourself, or copy `app/` + `public/` + `next-env.d.ts` from a throwaway `create-next-app` scaffold (keep the injected `next.config.ts` with `output: 'standalone'`, `tsconfig.json`, `package.json`). `.env.example` is injected — copy it to `.env.local` and fill real values.
3. **gitleaks binary** (not an npm package): `brew install gitleaks` or download from `github.com/gitleaks/gitleaks/releases` — the pre-commit hook fails closed without it.
4. **Hooks:** `pnpm exec husky init` (the bootstrap already placed `pre-commit` and `commit-msg` in `.husky/`); verify with a test commit on a branch.
5. **Visual baselines:** the test scaffolding is already injected — `tests/setup.ts` (jest-dom matchers + MSW server lifecycle), `tests/msw/` (server + contract-mirroring handlers), and example `tests/unit/`, `tests/e2e/`, `tests/visual/` tests. Adapt the examples, generate visual baselines locally (`pnpm exec playwright test --project=visual --update-snapshots`), review the PNGs, commit them. CI never regenerates baselines.
6. **Database (do this before auth — auth generation needs a reachable DB):** start the local database with `docker compose up -d` (the injected `docker-compose.yml`) and point `DATABASE_URL` in `.env.local` at it. `prisma/schema.prisma` (starter: snake_case via `@map`, UUIDv7 PK via `@default(uuid(7))`, timestamptz, soft-delete as a per-model decision) and `lib/db.ts` (the server-only Prisma singleton) are injected — adapt the schema, then `pnpm exec prisma migrate dev` for the first migration (optionally `pnpm db:seed`). Migrations land in `prisma/migrations/**` — the CI guard watches that path (forward-only; **never `prisma db push` in production**). Query via `getDb()`.
7. **Auth schema:** with `DATABASE_URL` set and the DB running (step 6), generate Better Auth's four models (`User`/`Session`/`Account`/`Verification`) with `pnpm dlx @better-auth/cli generate` (Prisma output), merge into `prisma/schema.prisma`, and **reconcile column names to snake_case** via `@map`/`@@map` (data-modeling rule 1). Make your domain models' `userId` a real relation to `User`.
8. **Env validation at boot:** `instrumentation.ts` (injected) calls `serverEnv()` guarded on `NEXT_RUNTIME === 'nodejs'` so startup fails on bad config. **Call `serverEnv()` (and construct DB/auth clients) inside handlers / the request path, never at module top-level** — `next build` evaluates route modules, so a module-scope `serverEnv()` throws at build. `env.schema.ts` is import-safe; the discipline is on callers. Client code imports `clientEnv` only. `next.config.ts` (injected) sets `serverExternalPackages` for Better Auth + `pg` + `@prisma/client`.
9. **Container & deploy:** `Dockerfile` (injected, multi-stage, runs `prisma generate` at build and `prisma migrate deploy` on start) builds the standalone server. Push to a container PaaS (Railway/Fly/Render); inject `DATABASE_URL`/`BETTER_AUTH_*` as host env (never baked into the image). The release workflow attests SLSA build-provenance on the pushed image (ADR-S19) — verify it in your deploy step.
10. **After first push:** set branch protection per `<STANDARDS_PATH>/05-verification/ci-pipeline.md` (Bootstrap section) — all PR jobs as required checks (or run `bash scripts/setup-branch-protection.sh`).

### Stack-specific rules

1. **pnpm only.** Never npm/yarn; never edit `pnpm-lock.yaml` by hand.
2. **TypeScript strict stays strict.** No `any` (Biome errors), no `!` non-null assertions, no loosening `tsconfig.json` to make an error go away.
3. **Auth is Better Auth, with defense-in-depth.** Session checks happen in the route handler / server component (`auth.api.getSession(...)`) — **never in middleware alone** (CVE-2025-29927 / React2Shell; see agent-operating-rules guardrail 3). Keep Next.js on a patched version.
4. **Database via Prisma.** Schema lives in `prisma/schema.prisma`; every change ships as a generated migration (`prisma migrate dev`) reviewed in the PR and applied with `prisma migrate deploy`. **Never `prisma db push` against production** — prototyping only.
5. **Validation at the boundary with Zod.** Every Server Action, route handler, and form parses its input with a Zod schema; types are inferred from the schema (`z.infer`), shared front↔back — never duplicated by hand.
6. **Env vars only through `env.schema.ts`** (boot-validated). `process.env` reads anywhere else are a review violation. Server code calls `serverEnv()` **inside handlers/the request path, never at module top-level** (a module-scope call throws at `next build`); client code imports `clientEnv` (NEXT_PUBLIC_ only, read as literal property accesses — never loop over them). Importing `serverEnv` from a client component is a review violation: the values are undefined in the browser by design.
7. **Server Components by default; `'use client'` only when needed** (state, effects, browser APIs). Keep data fetching on the server.
8. **Testing split (Vitest cannot render async Server Components):** unit-test Server Actions, Zod schemas, hooks, and synchronous components with Vitest + Testing Library (MSW for network); cover async Server Components and full user flows with Playwright.
9. **Hooks are sacred:** pre-commit (lint-staged + gitleaks) and commit-msg (commitlint) run on every commit; do not bypass with `--no-verify`.
10. **Deployment is a container on a PaaS** (Railway/Fly/Render), not serverless — this preset exists for warm-server workloads (WebSockets, cron, long jobs, persistent process). Keep the image minimal (`output: 'standalone'`), pin the base image, and verify the build-provenance attestation before deploy.
