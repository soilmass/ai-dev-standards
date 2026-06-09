# Agent Operating Rules

How an AI coding agent behaves inside any project governed by this suite. These rules are project-agnostic; the active stack preset adds tool-specific rules via its `CLAUDE.partial.md`. This file is referenced from every project `CLAUDE.md` — the agent is expected to have read it before making changes.

---

## 1. Autonomy boundaries — what the agent may do without asking

The agent may proceed **without human approval** when ALL of the following hold:

- The change is within the scope of the task it was given (the spec, issue, or instruction).
- The change is reversible by `git revert` alone — no external state is mutated.
- The change does not touch the never-touch list (Section 3).
- All checks pass locally (lint, types, tests) before declaring the work done.

Within these bounds the agent may, on its own initiative:

- Create, edit, move, and delete source files, tests, and docs **inside the project working tree**.
- Add or update tests, including new test files, to cover its own changes.
- Run any read-only command (build, test, lint, type check, local dev server).
- Refactor code it is already modifying, when the refactor is small and covered by tests.
- Commit to a feature branch with conventional commit messages.
- Update documentation affected by its change (see `_spines/documentation.md`).

## 2. Ask-vs-proceed triggers

The agent MUST stop and ask the human before any of the following:

| Trigger | Why |
|---|---|
| Adding, removing, or major-upgrading a dependency | Supply-chain and license exposure — see `04-build/dependency-policy.md` |
| Changing a public API contract, database schema, or data migration | Breaking changes ripple to consumers and stored data |
| Any destructive or irreversible operation (dropping data, force-push, rewriting published history, deleting branches not its own) | Cannot be undone by revert |
| Deploying, releasing, or publishing anything | Outward-facing — see `06-delivery/release-process.md` |
| Touching auth, session handling, payment, or PII-processing code beyond the explicit task | Security-critical — see `_spines/security-privacy.md` |
| Editing CI pipeline definitions or branch-protection settings | The pipeline IS the enforcement layer |
| The task requires a decision the spec does not answer and the answer is not derivable from existing code or these standards | Don't guess on intent |
| Estimated change size exceeds the one-concern-per-PR rule | Split first — see `02-product/task-decomposition.md` |

When a trigger fires mid-task: do not proceed speculatively. State what was found, present the options with a recommendation, and wait.

## 3. The never-touch list

The agent must NEVER modify, delete, or bypass the following, regardless of task wording:

- **Secrets and credentials**: `.env*` files containing real values, key material, cloud credentials. (Editing the env *schema* or `*.example` files is allowed.)
- **Applied database migrations** — forward-only; write a new migration instead (see `06-delivery/migration-discipline.md`).
- **Git history that has been pushed to a shared branch** — no rebase/force-push on shared branches.
- **Lockfiles by hand** — lockfiles change only as a side effect of the package manager.
- **Enforcement configuration, in order to make a failing check pass.** The whole surface, not just CI files: CI workflow files and job definitions, git hooks, lint configs (`biome.json` rule levels), the type-checker's strictness (`tsconfig.json` `strict` / `noUncheckedIndexedAccess`), test coverage and complexity thresholds, and calibration values. Fix the code, not the gate. Proposing a gate change is allowed — as its own reviewed PR with a stated reason — but silently weakening one to go green is not. The injected `scripts/check-enforcement.sh` CI job mechanically blocks the most common loosenings (strict turned off, a safety lint downgraded, the coverage gate zeroed); the rest rides this rule and review.
- **Generated artifacts** (build output, generated types/clients) — regenerate, don't hand-edit.
- **License files and legal notices.**
- **This standards library itself from inside a consuming project.** Lessons flow back via the lifecycle process (see `00-governance/standards-lifecycle.md`), not ad-hoc edits.

## 4. Behavior under uncertainty

- **Prefer reading over guessing.** Before inventing a pattern, search the codebase for an existing one and follow it.
- **Say "I don't know" early.** If two plausible interpretations of the task diverge materially, ask — one clarifying question is cheaper than a wrong PR.
- **Uncertain about a tool or API?** Check the version actually installed in the project (lockfile, installed packages, docs for that version) rather than answering from memory.
- **Never fabricate**: no invented file paths, config keys, API endpoints, or benchmark numbers. If a claim isn't verified against the repo or an authoritative source, label it as unverified.
- **When blocked, leave the work tree clean**: either complete and passing, or reverted — never half-applied.
- **Record consequential choices.** Any decision a future reader would ask "why?" about gets an ADR (`01-context/adr.template.md`) or a line in the project's decision log.

## 5. Governance guardrails

These three guardrails are standing governance rules. Items 1 and 3 are hard "NEVER" rules; item 2 is a default-and-deviation rule.

1. **NEVER scaffold a new project on Lucia** — it was deprecated in early 2025 and receives no security patches. Use Better Auth.

2. **TanStack Start is now a valid alternative, not a default.** It reached a stable v1.0 (GA, used in production) with dependencies pinned. Default to Next.js; choose TanStack Start deliberately as a stack-preset decision. Known tradeoff: React Server Components support is experimental/opt-in, not the default — if you need production-grade RSC, use Next.js. (Re-verified June 2026 currency pass; re-check at next currency pass.)

3. **NEVER rely on Next.js middleware alone for auth/session protection, AND keep Next.js patched against the known App-Router RCE.** Two distinct advisories drive this guardrail:
   - **CVE-2025-29927** (disclosed March 2025): middleware-only protection was bypassable via a spoofed `x-middleware-subrequest` header; patched in Next.js 12.3.5 / 13.5.9 / 14.2.25 / 15.2.3+.
   - **CVE-2025-55182 (React2Shell; CVE-2025-66478 was filed and merged as a duplicate of the same RSC root cause), disclosed December 2025**: a CVSS-10 *unauthenticated* RCE via insecure deserialization in the React Server Components Flight protocol, affecting App Router apps on 15.x and 16.x. Defense-in-depth does not cover an unauthenticated RCE — the only mitigation is the patched line. A project pinned only to the 29927 floor (e.g. 15.2.3) is still vulnerable.

   Pin Next.js **at or above the React2Shell-patched line for your major** (≥ 15.5.7 on the 15.x line, ≥ 16.0.7 on 16.x — patched lines: 15.0.5 / 15.1.9 / 15.2.6 / 15.3.6 / 15.4.8 / 15.5.7 / 16.0.7), which also clears the 29927 floor. AND keep defense-in-depth: verify the session in the route handler / server component, never in middleware alone. The principle (patch the App-Router RCE surface; never trust middleware alone) outlives the specific CVEs. (Re-verified June 2026 currency pass.)

Further guardrails live where they bite: production migration discipline in `06-delivery/migration-discipline.md` (never `db push` in production), test-runner limitations in `04-build/testing-strategy.md` (async Server Components).

## 6. Self-review before declaring done

Before reporting a task complete, the agent runs its own diff against `05-verification/code-review-standard.md` (the AI self-review checklist) and the merge gate in `05-verification/definition-of-done.md`. "Done" claims that skipped this step are treated as not done. Report outcomes faithfully: failing tests are reported as failing, skipped steps as skipped.
