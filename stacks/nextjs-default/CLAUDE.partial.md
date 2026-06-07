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

### Stack-specific rules

1. **pnpm only.** Never npm/yarn; never edit `pnpm-lock.yaml` by hand.
2. **TypeScript strict stays strict.** No `any` (Biome errors), no `!` non-null assertions, no loosening `tsconfig.json` to make an error go away.
3. **Auth is Better Auth, with defense-in-depth.** Session checks happen in the route handler / server component (`auth.api.getSession(...)`) — **never in middleware alone** (CVE-2025-29927; see agent-operating-rules guardrail 3). Keep Next.js on a patched version.
4. **Database via Drizzle.** Schema lives in `db/schema.ts`; every change ships as a generated migration (`drizzle-kit generate`) that is reviewed in the PR. **Never `drizzle-kit push` against production** — prototyping only.
5. **Validation at the boundary with Zod.** Every Server Action, route handler, and form parses its input with a Zod schema; types are inferred from the schema (`z.infer`), shared front↔back — never duplicated by hand.
6. **Env vars only through `env.schema.ts`** (boot-validated). `process.env` reads anywhere else are a review violation. Client-side vars need the `NEXT_PUBLIC_` prefix and contain no secrets.
7. **Server Components by default; `'use client'` only when needed** (state, effects, browser APIs). Keep data fetching on the server.
8. **Testing split (Vitest cannot render async Server Components):** unit-test Server Actions, Zod schemas, hooks, and synchronous components with Vitest + Testing Library (MSW for network); cover async Server Components and full user flows with Playwright.
9. **Hooks are sacred:** pre-commit (lint-staged + gitleaks) and commit-msg (commitlint) run on every commit; do not bypass with `--no-verify`.
10. **Deployment is Vercel**, preview deploy per PR. If a feature needs WebSockets, cron, or long-running jobs, raise the three-box question (see `pinned-decisions.md`) rather than contorting it into serverless.
