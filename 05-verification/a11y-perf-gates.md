# Accessibility & Performance Gates

Accessibility and performance are merge criteria, not launch-week cleanup. Both are gated twice: fast checks in the unit tier, full audits against the preview deploy.

## Accessibility

- **Target: WCAG 2.2 AA** for all user-facing pages and components.
- **Unit tier (every PR):** automated accessibility assertions run inside component tests — axe-based checks on rendered output, plus the discipline that role/label-based test queries impose (an unnameable control is a failing test by construction).
- **Preview tier (every PR):** the Lighthouse accessibility category runs against the preview deploy with a minimum score of **0.95**.
- Automated checks catch roughly half of WCAG; the remainder (focus order, meaningful alt text, keyboard traps) rides the self-review checklist via the UI standard (`03-design/ui-design-system.md`).

## Performance — Core Web Vitals

Budgets asserted by Lighthouse CI on every PR's preview deploy (3 runs, median, **mobile emulation** — Lighthouse's default and the form factor field CWV and search ranking actually measure; a desktop-only gate would pass CI while shipping mobile regressions):

| Metric | Budget |
|---|---|
| Largest Contentful Paint (LCP) | ≤ 2.5 s |
| Cumulative Layout Shift (CLS) | ≤ 0.10 |
| Total Blocking Time (TBT, lab proxy for INP) | ≤ 200 ms |
| Lighthouse performance score | ≥ 0.90 |
| Lighthouse best-practices / SEO scores | ≥ 0.90 |

- Budgets live in `lighthouserc.json` **in the repo**, so loosening one is a visible, reviewable diff — never a silent dashboard edit. A budget change requires a stated reason in the PR.
- A PR that blows a budget fixes the regression or explicitly raises the budget with justification; "merge now, optimize later" is how budgets die.
- Real-user monitoring (field data) complements these lab gates — see `07-operations/observability.md`.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (test job: a11y unit checks; lighthouse job) + stacks/nextjs-default/ci/lighthouserc.json (budgets)
- Fallback if unenforceable: n/a — automated halves are CI-gated; the manual accessibility remainder is carried by the UI design system's review items in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: `lighthouserc.json` (the budgets) at the project root and the PR workflow that runs both gates.
