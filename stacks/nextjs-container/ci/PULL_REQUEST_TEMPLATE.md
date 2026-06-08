<!-- PULL_REQUEST_TEMPLATE.md — copied to the project root by new-project.sh.
     The checkboxes below ARE the merge gate (05-verification/definition-of-done.md);
     an unchecked box means the PR is not ready for review. -->

## What & why

<!-- One concern per PR. Link the spec/issue this implements. -->

Closes #

## Definition of done

- [ ] Scope: this PR implements one concern, within the linked spec's scope and non-goals
- [ ] Tests: new/changed behavior is covered (unit/component via the test runner; flows via E2E where applicable)
- [ ] All local checks pass: lint + format, type check, test suite
- [ ] Self-review done against `05-verification/code-review-standard.md` — misses fixed or justified below
- [ ] Docs updated in this PR (architecture map / glossary / runbooks / ADR), or none needed
- [ ] DB changes (if any) ship as new forward-only migration files; no applied migration edited
- [ ] Rollback path stated below (revert / flag off / roll-forward migration)
- [ ] No secrets, credentials, or real env values introduced anywhere in the diff

## Rollback path

<!-- How this change is undone in production if it goes wrong. -->

## Self-review notes

<!-- Checklist misses you chose to accept, with justification. "None" is a valid entry. -->
