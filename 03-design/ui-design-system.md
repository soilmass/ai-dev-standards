# UI & Design System

Component structure and styling discipline. The styling system itself is a stack choice (named in the preset); the structural rules below hold regardless.

## One styling system

1. The project uses **exactly one** styling system — the one the active stack preset names — applied one way. No parallel CSS approaches accreting per feature; an agent finding two styles in the codebase asks which is canonical instead of adding a third.
2. Design tokens (color, spacing, type scale, radii) are defined once in the styling system's config and referenced everywhere. Raw hex values and magic pixel numbers in component code are violations.
3. Dark mode / theming, if present, works through tokens — never per-component conditionals.

## Component structure

4. Components are organized by visibility of purpose:
   - **Primitives** — buttons, inputs, dialogs: generic, styled via tokens, no business logic.
   - **Composites** — feature components assembled from primitives; may know domain types.
   - **Views/pages** — route-level assembly, data wiring per the architecture standards.
5. A primitive never imports from a feature; a feature never re-implements an existing primitive with local tweaks — extend the primitive's API instead.
6. Component props are typed narrowly (variants as unions, not free strings) so misuse is a compile error.
7. State lives as low as possible; server-derived data follows the stack's data-fetching rules (preset `CLAUDE.partial.md`), not ad-hoc client caches.

## Accessibility baseline

8. The accessibility bar and budgets live in `05-verification/a11y-perf-gates.md` (WCAG 2.2 AA; axe checks in the unit tier; Lighthouse on preview). Structural consequences here:
   - Interactive elements are real elements (`button`, `a`, `label`) — div-with-onClick fails review.
   - Every interactive component is keyboard-operable and visibly focusable; every form control has a programmatic label; images carry meaningful `alt` (or empty alt when decorative).
   - Component tests query by **role and accessible name**, which makes unnameable controls fail by construction.

## Enforcement
- Mechanism: lint rule
- Config: stacks/nextjs-default/lint-config/biome.json (a11y rule set: recommended, error level) + stacks/nextjs-default/ci/pr.yml (a11y unit checks + Lighthouse gate)
- Fallback if unenforceable: n/a — markup-level a11y and styling violations are lint/CI-gated; the manual remainder (focus order, alt quality) rides the threat-model-style review items already in the self-review checklist via `05-verification/a11y-perf-gates.md`.

## Bootstrap
- What new-project.sh injects for this standard: the lint config with the a11y rules at error level, and the CI gates that audit the preview deploy.
