# Pinned Technology Decisions

The standing tool recommendations behind the default stack preset, kept as a living reference. **This is the one global file permitted to name tools.** Everything here is framed as *defaults plus deviation rules*, not immutable law: the default preset uses the Primary column; the Deviation rule says when a *second preset* is warranted. Never silently substitute — a deviation is a new preset plus an ADR.

Snapshot date: June 2026 (currency pass 2026-06-07). Re-verify confidence levels at each currency pass (see `00-governance/standards-lifecycle.md`).

---

## The table

| Cell | Primary (default preset) | Deviation rule → second preset | Confidence |
|---|---|---|---|
| Package manager | **pnpm** | none — universal | Locked |
| Monorepo orchestration | **Turborepo** (only if multi-package) | Nx only if you need code generators / polyglot | Locked |
| Language | **TypeScript, strict mode** | none | Locked |
| Lint + format | **Biome** | ESLint + Prettier hybrid if security-critical or heavy ESLint-plugin needs | Default (swappable) |
| Unit / integration tests | **Vitest** | none | Locked |
| Component tests | **Testing Library** | none | Locked |
| API mocking | **MSW** | none | Locked |
| E2E tests | **Playwright** | none | Locked |
| Schema / validation | **Zod** | none | Locked |
| Git hooks | **Husky + lint-staged** | none | Locked |
| Commit format | **commitlint** (Conventional Commits) | none | Locked |
| Secret scanning | **gitleaks** | none | Locked |
| Dependency updates | **Dependabot** | Renovate if monorepo grouping/policy outgrows it | Locked |
| CI | **GitHub Actions** | none | Locked |
| Framework | **Next.js** | SvelteKit if leaving React for DX/perf; TanStack Start for type-safe Vite-native (RSC experimental/opt-in, not default) | Pinned |
| ORM | **Drizzle** (edge/serverless + AI-agent-friendly default) | Prisma if on a warm Node server and you want the most mature migration tooling | Pinned (rule) |
| Auth | **Better Auth** | Clerk if you want zero-maintenance managed auth; NEVER Lucia (deprecated) | Pinned |
| Hosting | **Vercel** (frontend) | Railway/Fly.io for heavy backend (WebSockets, cron, long jobs); Coolify/VPS at scale | Pinned (rule) |

Confidence legend — **Locked**: settled in current practice, change only with strong cause. **Pinned**: deliberate default with named alternatives. **Pinned (rule)**: the *rule* is pinned, the tool follows from your architecture. **Default (swappable)**: a deliberate default, expected to be swapped in specific contexts.

---

## Decision rules stated in full

These cells are *rules*, not single picks, because this library is reused across projects with different runtimes. Preserve the rule in global docs; collapse it to one tool only inside a stack preset.

### ORM — decide by *where the code runs*

- **Edge / serverless** (cold starts matter) → **Drizzle**: faster cold start and no codegen step on edge/serverless, AI-editor-friendly (plain TypeScript the agent can read and edit directly). (The pre-Prisma-7 gap was 3–5x; Prisma 7's Rust-free TypeScript client narrows but does not close it — re-verified June 2026 currency pass.)
- **Warm Node server** valuing the most mature migration tooling → **Prisma**.
- APIs are converging, so pick on architecture fit, not syntax taste. Industry drift is Prisma→Drizzle, not the reverse.
- Either way, production changes go through generated, reviewed migration files — see `06-delivery/migration-discipline.md`.

### Hosting — the three-box model

1. **Frontend** on an edge/CDN host (Vercel for Next.js).
2. **Backend that needs WebSockets, cron, or long-running jobs** on a container PaaS (Railway, Render, Fly.io).
3. **State** on a managed DB.

Start on Vercel for speed; evaluate Railway/self-host (Coolify/VPS) as cost becomes meaningful. Don't contort a long-running workload to fit a serverless host — move the box.

### Linter — the one open call

**Biome** is the greenfield default: one Rust binary replaces ESLint+Prettier, ~10–20x faster, imperceptible pre-commit hooks — which matters most for AI-agent-driven, high-frequency commits. Switch to the **ESLint + Prettier hybrid** only for security-critical codebases or where specific ESLint plugins (e.g. niche a11y/security rules) are required. This is a **stack choice**: it lives in a preset (`stacks/<stack>/lint-config/`), never in a global rule.

### Auth — hard floor

Better Auth is the self-hosted default; Clerk when you want zero-maintenance managed auth. **Lucia is never acceptable** — deprecated early 2025, no security patches (see guardrail 1 in `00-governance/agent-operating-rules.md`).

---

## Currency pass checklist

The twice-yearly pass (see `00-governance/standards-lifecycle.md`) is concrete work, not a glance:

1. Walk every table row: check each tool for deprecation notices, security advisories, major releases, and ecosystem drift (is the industry default moving away from it?).
2. Re-verify the dated guardrails in `00-governance/agent-operating-rules.md` — a guardrail naming a deprecated tool or a "as of <date>" claim is the first thing to go stale.
3. Update the **Snapshot date** at the top of this file.
4. Patch any affected preset ADRs (`stacks/nextjs-default/stack-decisions.md`) in the same change — the table and its ADRs must never drift.
5. Record the pass in the library's git history as a tagged commit, so each currency review is locatable later.

## How these decisions are consumed

- Each pinned tool has a pre-written ADR in `stacks/nextjs-default/stack-decisions.md` — choice, rationale, accepted tradeoff.
- A new project never re-litigates this table; it picks a preset via `scripts/new-project.sh`.
- A project whose constraints genuinely break a deviation rule's threshold gets a **new preset** (see `stacks/README.md`), and the lesson may flow back here as a patch (see `00-governance/standards-lifecycle.md`).
