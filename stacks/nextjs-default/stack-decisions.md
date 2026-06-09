# Stack Decisions — nextjs-default

Pre-written ADRs for every pinned tool in this preset. Each records the choice, the rationale, and the accepted tradeoff, so a new project never re-litigates them. Source table and deviation rules: `00-governance/pinned-decisions.md`. Status of all ADRs below: **Accepted** (snapshot June 2026).

---

## ADR-S01: pnpm as package manager

- **Decision:** All projects on this preset use pnpm; lockfile is `pnpm-lock.yaml`.
- **Rationale:** Content-addressed store gives the fastest installs and the least disk use; strict node_modules layout surfaces phantom dependencies that npm/yarn hoisting hides — which matters when an AI agent infers imports from what "happens to resolve".
- **Accepted tradeoff:** Occasional tooling that assumes npm needs a flag or shim; contributors must have pnpm installed (`corepack enable`).

## ADR-S02: Turborepo for monorepo orchestration (only if multi-package)

- **Decision:** Single-package projects use plain pnpm scripts. The moment a repo becomes multi-package, add Turborepo — not Nx.
- **Rationale:** Turborepo layers task caching and pipelines on top of pnpm workspaces with near-zero config and no framework lock-in. Nx's strengths (code generators, polyglot plugins) are unneeded here per the deviation rule.
- **Accepted tradeoff:** No generator ecosystem; cache configuration is on us. Re-evaluate toward Nx only if generators/polyglot become real needs.

## ADR-S03: TypeScript, strict mode

- **Decision:** `"strict": true` plus `noUncheckedIndexedAccess`; never loosened per-file to silence errors.
- **Rationale:** The type checker is the cheapest reviewer an AI-driven workflow has — it catches the agent's plausible-but-wrong code at compile time. Strictness from day one is free; retrofitting it is a project.
- **Accepted tradeoff:** More upfront type ceremony, occasional friction with loosely-typed libraries (solved with module augmentation, not `any`).

## ADR-S04: Biome for lint + format

- **Decision:** Biome replaces ESLint + Prettier; config at `lint-config/biome.json`.
- **Rationale:** One Rust binary, one config, ~10–20x faster — pre-commit stays imperceptible, which matters most for AI-agent-driven, high-frequency commits. Covers lint, format, and import organization in a single pass.
- **Accepted tradeoff:** Smaller plugin ecosystem than ESLint. Per the deviation rule this is the **swappable** cell: switch to the ESLint + Prettier hybrid for security-critical codebases or hard requirements on specific ESLint plugins — as a preset change, recorded here.

## ADR-S05: Vitest for unit/integration tests

- **Decision:** Vitest is the unit and integration test runner.
- **Rationale:** Native ESM + TypeScript, shares config with the Vite-based toolchain, fast watch mode, Jest-compatible API (so agents' Jest-shaped knowledge transfers directly).
- **Accepted tradeoff:** It cannot render **async Server Components** — that coverage moves to Playwright by rule (see `04-build/testing-strategy.md`).

## ADR-S06: Testing Library for component tests

- **Decision:** React Testing Library on top of Vitest for component tests.
- **Rationale:** Queries by role/label force accessible markup as a side effect of testing; tests assert user-visible behavior, not implementation details — so refactors don't shred the suite.
- **Accepted tradeoff:** Less direct access to component internals; some interactions are easier to assert in Playwright — that's the intended split.

## ADR-S07: MSW for API mocking

- **Decision:** Mock Service Worker intercepts network calls in component/integration tests (and optionally in dev).
- **Rationale:** Mocks at the network boundary, not the module boundary — the code under test runs its real fetch path, and the same handler definitions serve tests and local dev.
- **Accepted tradeoff:** One more moving piece in test setup; handlers must be kept honest against the real API contract (see `03-design/api-contract-design.md`).

## ADR-S08: Playwright for E2E

- **Decision:** Playwright runs the E2E suite (nightly + pre-deploy) and the visual-regression project; also owns async-Server-Component coverage.
- **Rationale:** First-class multi-browser support, auto-waiting that kills flake, trace viewer for debugging CI failures, and a screenshot baseline workflow good enough for visual regression without a paid service.
- **Accepted tradeoff:** Slow relative to unit tests — which is why scope is capped (≈20–30 tests on revenue-critical paths) and the full suite runs nightly, not per-PR.

## ADR-S09: Zod for schema/validation

- **Decision:** Zod schemas validate every external input (forms, route handlers, Server Actions, env) and are the single source of shared types via `z.infer`. **Pin `zod@^4`** — Better Auth's current line (1.6.x, ADR-S11) requires it as a peer.
- **Rationale:** Runtime validation + static types from one declaration closes the gap TypeScript leaves at runtime boundaries; the env schema (`env.schema.ts`) makes config failures boot-time, not request-time.
- **Accepted tradeoff:** Bundle cost on the client where schemas are imported; keep client schemas lean. zod 4 moved string formats to top-level (`z.url()`, `z.email()`) — the env-schema example uses these; the deprecated `z.string().url()` method form is avoided (surfaced by the first project, flow-back FB-01).

## ADR-S10: Drizzle as ORM (with documented Prisma swap)

- **Decision:** Drizzle + drizzle-kit for schema, queries, and migrations.
- **Rationale:** The preset deploys to edge/serverless (Vercel), where Drizzle's faster cold start and zero codegen step win per the ORM decision rule. (The pre-Prisma-7 cold-start gap was 3–5x; Prisma 7's Rust-free TypeScript client narrows but does not close it — re-verified June 2026 currency pass.) Plain-TypeScript schema is the most AI-agent-friendly surface — the agent reads and edits the real source, not a DSL.
- **Prisma swap:** If a project moves to a warm Node server and wants the most mature migration tooling, swap to Prisma **as a new preset** — port `db/schema.ts` to `schema.prisma`, replace drizzle-kit commands, keep the same migration discipline (`06-delivery/migration-discipline.md`). The rule (decide by where the code runs) stays; only the pick changes.
- **Accepted tradeoff:** Migration tooling is younger than Prisma's; some complex relational queries take more SQL-shaped code.

## ADR-S11: Better Auth for authentication

- **Decision:** Better Auth, self-hosted, with session verification in route handlers / server components. **Peer-version coupling:** the 1.6.x line requires `zod@^4` (ADR-S09) and `drizzle-orm@^0.45.2` / `drizzle-kit@^0.31.4` (ADR-S10) — pin all three together; bumping Better Auth re-checks these peers.
- **Rationale:** Modern, actively maintained, framework-agnostic TypeScript auth with ownership of the user table (no per-MAU pricing). The deviation is Clerk when zero-maintenance managed auth is worth the vendor coupling. **Lucia is banned** — deprecated early 2025, no security patches (governance guardrail 1).
- **Accepted tradeoff:** We own session storage, email flows, and security updates that a managed provider would absorb. Defense-in-depth rule applies regardless (guardrail 3: never middleware-only).

## ADR-S12: Husky + lint-staged for git hooks

- **Decision:** Husky manages hooks; pre-commit runs lint-staged (Biome on staged files) + gitleaks; commit-msg runs commitlint. Hook sources live in `hooks/` and are copied by the bootstrap.
- **Rationale:** Catch violations seconds after they're written, not minutes later in CI — the fast feedback that keeps agent loops tight. lint-staged keeps it O(changed files).
- **Accepted tradeoff:** Hooks are client-side and bypassable (`--no-verify`); CI re-runs the same checks as the authoritative gate.

## ADR-S13: commitlint (Conventional Commits)

- **Decision:** Every commit message passes commitlint with `config-conventional` (`hooks/commitlint.config.mjs`).
- **Rationale:** Machine-parseable history enables changelog generation and semantic releases (`06-delivery/release-process.md`), and forces the one-concern-per-commit habit.
- **Accepted tradeoff:** Slight ceremony on quick fixes; `chore:` exists for a reason.

## ADR-S14: gitleaks for secret scanning

- **Decision:** gitleaks runs in pre-commit (`protect --staged`) and in CI on full history.
- **Rationale:** A leaked secret in git history is permanent-until-rotated; the cheapest fix is the one that blocks the commit. Default ruleset covers the common credential shapes; custom rules can be added per-project.
- **Accepted tradeoff:** Occasional false positives (high-entropy test fixtures) — handled with inline `# gitleaks:allow` on the specific line, never by disabling the scan.

## ADR-S15: Dependabot for dependency updates

- **Decision:** Dependabot, weekly, with minor/patch grouped (`dependabot.yml`); security updates immediate.
- **Rationale:** Native to GitHub, zero infrastructure, and the grouping config keeps PR noise tolerable for a solo developer. Policy in `08-maintenance/dependency-updates.md`.
- **Accepted tradeoff:** Renovate's richer grouping/scheduling is better for large monorepos — that's the documented deviation if this outgrows Dependabot.

## ADR-S16: GitHub Actions for CI

- **Decision:** GitHub Actions runs the pinned pipeline: `ci/pr.yml` (per-PR tiers), `ci/nightly.yml` (full E2E + visual regression), and `ci/release.yml` (tag-triggered changelog/release).
- **Rationale:** Co-located with the repo and the PR gate it enforces; marketplace actions cover the Vercel-preview wait and Lighthouse steps; free tier is ample for solo scale.
- **Accepted tradeoff:** Vendor lock-in to GitHub; YAML duplication across workflows is kept minimal by keeping logic in package scripts.

## ADR-S17: Next.js as framework

- **Decision:** Next.js, App Router, Server Components by default; version pinned ≥ the React2Shell-patched line for its major (≥ 15.5.7 on the 15.x line, ≥ 16.0.7 on 16.x), which also clears the older CVE-2025-29927 floor.
- **Rationale:** The most mature React full-stack framework: RSC support, first-class Vercel deployment, the largest knowledge base (which AI agents have deepest training coverage of). Deviations per `00-governance/pinned-decisions.md`: SvelteKit (leaving React), TanStack Start (type-safe Vite-native, RSC experimental/opt-in not the default — governance guardrail 2).
- **Accepted tradeoff:** Framework complexity (caching layers, server/client boundary) and a degree of Vercel gravity; both are managed by the standards rather than avoided. The App Router's RSC surface carries an active RCE history (CVE-2025-29927 middleware bypass; CVE-2025-55182 / React2Shell unauthenticated RCE) — the version-pin floor above and guardrail 3 in `00-governance/agent-operating-rules.md` are the standing mitigation (re-verified June 2026 currency pass).

## ADR-S18: Vercel for hosting

- **Decision:** Frontend deploys to Vercel — preview deploy per PR, production from `main`.
- **Rationale:** Zero-config Next.js deploys, preview URLs that the CI Lighthouse gate runs against, edge network by default. Box 1 of the three-box model (`00-governance/pinned-decisions.md`).
- **Accepted tradeoff:** Cost curve at scale and serverless limits (no WebSockets/long jobs). The rule, not this pick, is pinned: workloads that outgrow box 1 move to a container PaaS (Railway/Fly.io) — raise it as an architecture decision, don't contort the app.
