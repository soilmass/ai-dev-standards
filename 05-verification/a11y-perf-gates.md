# Accessibility & Performance Gates

Accessibility and performance are merge criteria, not launch-week cleanup. Both are gated twice: fast checks in the unit tier, full audits against the preview deploy.

## Route coverage — every sitemap route, not only home

These gates run against **every route in the site's sitemap**, not just the home page or a sampled first-N. The Lighthouse CI job derives its URL list from the deployed site's `sitemap.xml` (rooted at the preview deploy URL) and audits each route, so the accessibility, performance, and SEO floors below apply uniformly to every page the site ships. A site whose home page passes while an interior route regresses **fails** the gate — there is no per-page quality tier. This is the enforcement arm of `03-design/per-page-quality-baseline.md` (the per-route content bar: one `<h1>`, unique bounded title/description, complete metadata). The Lighthouse knobs that govern the run — `numberOfRuns 3` + mobile emulation (CAL-C09) and the category/metric floors (CAL-C02–C08) — apply identically to **each** audited route; the run multiplies across routes, the thresholds do not change per route.

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
| Total Blocking Time (TBT, lab proxy for INP) | ≤ 300 ms |
| Lighthouse performance score | ≥ 0.90 |
| Lighthouse best-practices / SEO scores | ≥ 0.90 |

- Budgets live in `lighthouserc.json` **in the repo**, so loosening one is a visible, reviewable diff — never a silent dashboard edit. A budget change requires a stated reason in the PR.
- A PR that blows a budget fixes the regression or explicitly raises the budget with justification; "merge now, optimize later" is how budgets die.
- Real-user monitoring (field data) complements these lab gates — see `07-operations/observability.md`.

## Standards basis

- **WCAG 2.2 Level AA** (W3C Recommendation, Oct 2023 — w3.org/TR/WCAG22/): the conformance target this doc names; AA includes all A + AA success criteria and is what ADA Title II, Section 508, and the EU Accessibility Act require. WCAG 3.0 remains a Working Draft (no Recommendation expected before ~2029), so 2.2 AA is the current operative standard. The "automated checks catch ~half of WCAG" caveat reflects that many criteria (focus order, alt-text meaning, keyboard traps) are not machine-decidable and ride the self-review checklist.
- **Core Web Vitals** (web.dev): the three CWV are LCP (loading, good ≤ 2.5 s), CLS (visual stability, good ≤ 0.10), and **INP** (responsiveness, good ≤ 200 ms) — INP replaced FID as the responsiveness CWV on 12 Mar 2024. Field CWV are assessed at the 75th percentile of real users; the gate uses **TBT ≤ 300 ms** as Lighthouse's lab proxy for INP because INP itself requires field interaction data (see observability for the RUM half).
- **Lighthouse performance scoring** (GoogleChrome/lighthouse): the lab score is a weighted blend dominated by TBT (~30%), LCP (~25%), and CLS (~25%), with FCP and Speed Index (~10% each) — so the per-metric budgets and the ≥ 0.90 aggregate floor reinforce rather than duplicate each other.
- **Mobile-first measurement** (web.dev / Google Search): CWV and search ranking use field data weighted toward mobile; Lighthouse's default mobile emulation aligns the lab gate with what users and ranking actually experience.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/pr.yml (test job: a11y unit checks; lighthouse job) + stacks/nextjs-default/ci/lighthouserc.json (budgets)
- Fallback if unenforceable: n/a — automated halves are CI-gated; the manual accessibility remainder is carried by the UI design system's review items in the self-review checklist.

## Bootstrap
- What new-project.sh injects for this standard: `lighthouserc.json` (the budgets) at the project root and the PR workflow that runs both gates.
