# Stack Presets

A **stack preset** is where choices live. Global standards (`00`–`08`, `_spines/`) state the rules; a preset commits to specific tools and ships the real, known-good configs that enforce those rules. A new project picks exactly one preset at bootstrap (`scripts/new-project.sh <dir> <preset>`).

Available presets:

| Preset | Stack | Status |
|---|---|---|
| [`nextjs-default/`](nextjs-default/) | Next.js + TS-strict + Biome + Vitest/TL/MSW + Playwright + Zod + Drizzle + Better Auth + Husky/commitlint/gitleaks + Dependabot + GitHub Actions → Vercel | Default |

## The preset contract

Every preset MUST contain all of the following. `new-project.sh` and the completeness matrix assume this shape; a preset missing a piece is not a preset.

| Artifact | Purpose |
|---|---|
| `stack-decisions.md` | A real ADR for **every** tool the preset pins — choice, rationale, accepted tradeoff. No tool enters the preset without one. |
| `CLAUDE.partial.md` | Stack-specific agent rules + command table, appended to the project `CLAUDE.md` at bootstrap. Keep it as lean as the template it merges into. |
| `lint-config/` | The real lint/format config file(s), copied verbatim into new projects. |
| `ci/` | Real CI workflow files implementing the pinned pipeline of `05-verification/ci-pipeline.md` — at minimum a per-PR workflow, a nightly/pre-deploy workflow, and a tag-triggered release workflow, plus any budget/config files they reference. |
| `hooks/` | Real git hook scripts (pre-commit, commit-msg) and the configs they invoke (lint-staged, commitlint). |
| `dependabot.yml` | Real dependency-update config implementing `08-maintenance/dependency-updates.md`. |
| `env.schema.example` | Real boot-validated env schema example implementing `04-build/secrets-config.md` (server/client split). |
| `project-config/` | Per-project tool configs the CI gates depend on (test runner with coverage thresholds, E2E/visual config, ORM config pinning the migrations path, gitignore), plus runnable test scaffolding (test setup + network-mock server/handlers + example unit/E2E/visual tests), the boot-validation hook (`instrumentation.ts` calling the env schema), and a data-model schema starter — copied **recursively** to the project root, relative paths preserved, with `.example` stripped. |

Layer-doc footers point into these paths (`Config: stacks/<stack>/<path>`). If you add a preset, every footer reference must resolve for your stack too — or the doc's enforcement is honestly re-declared for that stack.

## Adding a new preset

1. **Justify it.** A new preset exists only when a deviation rule in `00-governance/pinned-decisions.md` fires (e.g. warm-Node ORM, security-critical linter, heavy-backend hosting) or a genuinely different stack is adopted. Never fork a preset to dodge a rule.
2. **Copy the shape**, not the choices: create `stacks/<name>/` with every contract artifact above.
3. **Write the ADRs first** — one per tool, including for tools you kept from another preset (state "inherited, same rationale" + what differs).
4. **Wire the configs for real.** CI must implement the pinned pipeline stages; hooks must run the preset's linter and secret scan; the env schema must boot-validate. Empty shells fail the four-test bar.
5. **Test the bootstrap:** run `scripts/new-project.sh /tmp/test-proj <name>` and verify the assembled `CLAUDE.md` and copied configs work.
6. **Register it:** add a row to the table above and, if the preset changes a default, patch `00-governance/pinned-decisions.md` through the lifecycle process.
