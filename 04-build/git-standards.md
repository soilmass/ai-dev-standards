# Git Standards

How history is shaped. Machine-checkable parts (commit format, branch names) are enforced by hooks; the rest is review discipline.

## Branching model

1. **Trunk-based, short-lived branches.** `main` is always releasable; everything else is a branch off `main`, merged back via PR within days, not weeks.
2. Branch names: `<type>/<short-slug>` where `<type>` is one of the Conventional Commit types (`feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`). Enforced by the pre-commit hook.
3. No direct commits to `main` (hook-blocked locally; branch protection enforces it server-side).
4. Delete branches after merge.

## Commit format — Conventional Commits

5. Every commit message: `<type>(<scope>): <subject>` — subject ≤ 72 chars, imperative mood. Enforced by the commit-format linter in the commit-msg hook.
6. The body (when present) explains *why*; the diff already shows *what*.
7. One logical change per commit. "WIP" commits are fine on a branch but get squashed before merge.

## PR conventions

8. One concern per PR, within the size budget (`02-product/task-decomposition.md`) — enforced by the CI PR-size gate.
9. The PR description follows the injected template: linked spec/issue, the definition-of-done checklist, a stated rollback path.
10. PRs merge with green CI only; never merge with a failing or skipped required check.
11. Squash-merge is the default so `main` history stays one-commit-per-concern; the squash message itself follows Conventional Commits.

## History rules

12. Never rewrite history on a shared branch (`main` or anything someone else may have pulled). Force-push only to your own unshared branch.
13. Reverts use `git revert` (a new commit), preserving the audit trail — see `06-delivery/rollback.md`.

## Enforcement
- Mechanism: git hook
- Config: stacks/nextjs-default/hooks/ (pre-commit: branch-name gate; commit-msg: commitlint; commitlint.config.mjs)
- Fallback if unenforceable: n/a — format and branch rules are hook-enforced; PR conventions are enforced by the PR template and CI gates.

## Bootstrap
- What new-project.sh injects for this standard: the preset's hook scripts into `.husky/` (executable) plus `commitlint.config.mjs` and `lint-staged.config.mjs` at the project root.
