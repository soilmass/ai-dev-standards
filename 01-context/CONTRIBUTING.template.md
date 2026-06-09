# Contributing

## One-time setup

The exact, stack-specific steps — installing dependencies, wiring git hooks,
installing the secret scanner, and copying the environment file — are in the
**"Project setup after bootstrap"** section of `CLAUDE.md`. Run those first.

Then turn on verified signing once: `bash scripts/configure-signing.sh`
(commits and tags are expected to be signed; see the commit-signing standard).

## Workflow

- Branch from `main` as `<type>/<short-slug>`; types are the Conventional Commit
  set: `feat fix docs style refactor perf test build ci chore revert`.
- Write commits in Conventional Commits form — `<type>(<scope>): <subject>`,
  subject in the imperative and ≤ 72 chars. The commit-msg hook enforces this.
- Keep each PR to **one concern** and under the size gate. Fill in the pull-request
  template, including the **rollback path**.
- Run the test suite and the linter before pushing; **CI must be green to merge**,
  and merging is via squash so `main` stays one commit per concern.
- Self-review your diff against the code-review checklist before marking it done.

## Reporting issues

- Bugs and feature requests: use the issue templates.
- Security vulnerabilities: **do not** open a public issue — follow `SECURITY.md`.

See `CLAUDE.md` for the project's agent rules and the standards it follows.
