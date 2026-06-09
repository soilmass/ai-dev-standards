# UI & Design System

Component structure and styling discipline. The styling system itself is a stack choice (named in the preset); the structural rules below hold regardless.

## One styling system

1. The project uses **exactly one** styling system — the one the active stack preset names — applied one way. No parallel CSS approaches accreting per feature; an agent finding two styles in the codebase asks which is canonical instead of adding a third.
2. Design tokens (color, spacing, type scale, radii) are defined once in the styling system's config and referenced everywhere. Raw hex values and magic pixel numbers in component code are violations. The full token **taxonomy** (which DTCG groups the token set must cover), the alias-don't-duplicate rule, and the platform-guideline grounding (Apple HIG / Material 3 / WAI-ARIA APG borrow-vs-reject discipline + citation requirement) live in `03-design/design-tokens-and-hig.md` — this rule is its consuming consequence; do not restate the taxonomy here.
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

8. The accessibility bar and budgets live in `05-verification/a11y-perf-gates.md` (WCAG 2.2 AA; automated checks in the unit tier; full audit on the preview deploy). Structural consequences here:
   - Interactive elements are real elements (`button`, `a`, `label`) — div-with-onClick fails review.
   - Every interactive component is keyboard-operable and visibly focusable; every form control has a programmatic label; images carry meaningful `alt` (or empty alt when decorative).
   - Component tests query by **role and accessible name**, which makes unnameable controls fail by construction.
   - Pointer targets meet WCAG 2.2 **2.5.8 Target Size (Minimum)** — at least 24×24 CSS px (or equivalent spacing) — so the token-defined sizes for interactive primitives never drop below it; complex widgets follow the WAI-ARIA APG keyboard-interaction pattern for their role.

## Standards basis

- **WCAG 2.2 Level AA** (W3C Recommendation, 12 Dec 2024, https://www.w3.org/TR/WCAG22/): POUR — Perceivable, Operable, Understandable, Robust. Grounds the accessibility baseline: real semantic elements, keyboard operability + visible focus (2.4.7 / 2.4.11 Focus Not Obscured), programmatic labels (1.3.1, 4.1.2), meaningful/empty alt (1.1.1), and 2.5.8 Target Size.
- **WAI-ARIA Authoring Practices Guide (APG)** (https://www.w3.org/WAI/ARIA/apg/): authoritative role/state/keyboard-interaction patterns for composite widgets. Basis for "use the real element first, ARIA only to fill gaps" and the per-role keyboard expectations on composites.
- **W3C Design Tokens Format Module** (DTCG, first stable version Oct 2025; `.tokens`/`application/design-tokens+json`): a vendor-neutral interchange format for color/spacing/type/radii tokens with groups and aliases. Grounds rules 2–3 — tokens defined once, referenced everywhere, theming via token aliasing rather than per-component conditionals. The full taxonomy these rules consume, plus the Apple HIG / Material 3 grounding and borrow-vs-reject discipline, is fixed in `03-design/design-tokens-and-hig.md`.
- **Design-token / atomic structure** (single source of style; primitives→composites→views): grounds the component hierarchy (rules 4–5) and the no-parallel-styling-system rule (1).

## Enforcement
- Mechanism: lint rule
- Config: stacks/nextjs-default/lint-config/biome.json (a11y rule set: recommended, error level) + stacks/nextjs-default/ci/pr.yml (a11y unit checks + Lighthouse gate)
- Fallback if unenforceable: n/a — markup-level a11y and styling violations are lint/CI-gated; the manual remainder (focus order, alt quality) rides the threat-model-style review items already in the self-review checklist via `05-verification/a11y-perf-gates.md`.

## Bootstrap
- What new-project.sh injects for this standard: the lint config with the a11y rules at error level, and the CI gates that audit the preview deploy.
