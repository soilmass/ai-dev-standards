# CLAUDE.md — <PROJECT_NAME>

> Assembled from `ai-dev-standards` on <BOOTSTRAP_DATE> with stack preset `<STACK_PRESET>`. This file is an **index, not a manual**: non-negotiable rules are inline; everything else is a link. Keep it lean.

## Project identity

- **Name:** <PROJECT_NAME>
- **One-liner:** <WHAT_THIS_PROJECT_DOES_IN_ONE_SENTENCE>
- **Primary users:** <WHO_USES_IT>
- **Repository layout:** <MONOREPO_OR_SINGLE_PACKAGE_AND_KEY_DIRECTORIES>
- **Architecture map:** see `docs/architecture-map.md`
- **Glossary:** see `docs/glossary.md` — use these names consistently

## Non-negotiable rules (inline)

1. Follow the agent operating rules: `<STANDARDS_PATH>/00-governance/agent-operating-rules.md` — autonomy boundaries, ask-vs-proceed triggers, the never-touch list, and the governance guardrails. Read it before your first change.
2. Never commit secrets. Env vars go through the boot-validated schema (`env.schema`); `.env*` files with real values are untouchable.
3. All work lands via PR with green CI. Never weaken a gate (lint config, CI job, hook) to make it pass.
4. Database changes are forward-only, via generated + reviewed migration files. Never push schema changes directly to production.
5. One concern per PR. Oversized work gets split before it gets built.
6. Before declaring done: self-review your diff against `<STANDARDS_PATH>/05-verification/code-review-standard.md` and the definition of done.
7. <PROJECT_SPECIFIC_NON_NEGOTIABLE_OR_DELETE_THIS_LINE>

## Active stack preset

This project uses **`<STACK_PRESET>`** — see the merged stack rules below (appended from the preset's `CLAUDE.partial.md`) for tool names, commands, and stack-specific rules. Stack decisions and their rationale: `<STANDARDS_PATH>/stacks/<STACK_PRESET>/stack-decisions.md`.

## Standards by topic (links)

| Topic | Doc |
|---|---|
| Spec & scoping | `<STANDARDS_PATH>/02-product/spec.template.md`, `<STANDARDS_PATH>/02-product/task-decomposition.md`, `<STANDARDS_PATH>/02-product/acceptance-criteria.md` |
| Architecture & boundaries | `<STANDARDS_PATH>/03-design/architecture-standards.md` |
| Data modeling | `<STANDARDS_PATH>/03-design/data-modeling.md` |
| API contracts | `<STANDARDS_PATH>/03-design/api-contract-design.md` |
| UI & design system | `<STANDARDS_PATH>/03-design/ui-design-system.md` |
| Threat modeling | `<STANDARDS_PATH>/03-design/threat-model.template.md` |
| Coding standards | `<STANDARDS_PATH>/04-build/coding-standards.md` |
| Git & commits | `<STANDARDS_PATH>/04-build/git-standards.md` |
| Testing strategy | `<STANDARDS_PATH>/04-build/testing-strategy.md` |
| Dependencies | `<STANDARDS_PATH>/04-build/dependency-policy.md` |
| Secrets & config | `<STANDARDS_PATH>/04-build/secrets-config.md` |
| Definition of done | `<STANDARDS_PATH>/05-verification/definition-of-done.md` |
| Self-review checklist | `<STANDARDS_PATH>/05-verification/code-review-standard.md` |
| CI pipeline | `<STANDARDS_PATH>/05-verification/ci-pipeline.md` |
| A11y & performance gates | `<STANDARDS_PATH>/05-verification/a11y-perf-gates.md` |
| Deploy & release | `<STANDARDS_PATH>/06-delivery/` |
| Operations | `<STANDARDS_PATH>/07-operations/` |
| Maintenance | `<STANDARDS_PATH>/08-maintenance/` |
| Security spine | `<STANDARDS_PATH>/_spines/security-privacy.md` |
| Documentation spine | `<STANDARDS_PATH>/_spines/documentation.md` |

## Project-specific notes

<ANYTHING_THE_AGENT_MUST_KNOW_THAT_IS_UNIQUE_TO_THIS_PROJECT_OR_DELETE_THIS_SECTION>
