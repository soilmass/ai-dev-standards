# Accessibility & Inclusive UX Spine

Accessibility is not a layer — it's whether everyone can actually use what you built, and it is decided in design, written in build, and verified in CI. This spine doesn't duplicate the layer rules; it shows **where accessibility bites in each layer**, owns the cross-cutting obligations (the manual checks automation can't catch, the legal floor), and ties the design contract to the gate.

## Where it bites, layer by layer

| Layer | Accessibility obligation | Lives in |
|---|---|---|
| 02 Product | Acceptance criteria include the a11y bar for the feature (keyboard-operable, perceivable states, error messaging) | `02-product/acceptance-criteria.md` |
| 03 Design | WCAG 2.2 AA baseline (contrast, target size, focus visible); per-widget **ARIA keyboard contracts** for any custom composite | `03-design/ui-design-system.md`, `03-design/ui-accessibility-patterns.md` |
| 04 Build | Semantic HTML first; ARIA only to fill gaps; labels, names, and focus order correct in the markup | `04-build/coding-standards.md`, `03-design/ui-accessibility-patterns.md` |
| 05 Verification | Automated a11y unit checks + Lighthouse accessibility score gate the PR | `05-verification/a11y-perf-gates.md` |
| 06 Delivery | Preview deploy is eyeballed for the a11y-affecting change before promotion | `06-delivery/deployment-strategy.md` |
| 07 Operations | Client error tracking catches a11y-breaking runtime errors (focus traps, missing handlers) in the field | `07-operations/observability.md` |

## Cross-cutting rules owned here

1. **Semantic HTML is the default; ARIA is the exception.** A native `<button>`, `<a>`, `<label>`, `<dialog>`, or heading carries role, state, and keyboard behavior for free — reach for ARIA only to express what no native element can, and never to paper over the wrong element. "No ARIA is better than bad ARIA" (the first rule of ARIA use).
2. **Automated checks are necessary, not sufficient.** The Lighthouse/axe gate (`05-verification/a11y-perf-gates.md`) catches the deterministic ~30–40% (contrast, missing alt/label, ARIA misuse); it cannot judge focus order, keyboard operability of a custom widget, screen-reader sense, or whether an error is *perceivable*. Those need the manual walkthrough below — a green a11y score is a floor, not a pass.
3. **Every interactive thing is keyboard-operable, with visible focus, in a sensible order.** All functionality works without a mouse (WCAG 2.1.1), focus is always visible (2.4.7) and never trapped except in a modal that returns focus on close, and tab order follows reading order. The keyboard walkthrough is the single highest-value manual a11y check — do it on every UI change.
4. **Custom composite widgets implement their full APG contract.** Any combobox, dialog, menu, tabs, disclosure, or listbox follows its WAI-ARIA Authoring Practices keyboard map, single-tab-stop model, and roles/states — verified by keyboard-only walkthrough — or a native element is used instead. This is the design contract in `03-design/ui-accessibility-patterns.md`; this spine makes the manual verification non-optional.
5. **State and error are perceivable by more than one sense.** Don't signal meaning by color alone (WCAG 1.4.1); loading/empty/error/success states have a text/ARIA-live equivalent so a screen-reader or color-blind user gets the same information; form errors are programmatically associated with their field, not just colored red.
6. **Accessibility has a legal floor, so it is in scope by default.** WCAG 2.2 AA is the conformance target because it is what EN 301 549 (EU), the ADA (US, via DOJ guidance), and Section 508 effectively require — a11y is a baseline obligation for a public web app, recorded like any other acceptance criterion, not an enhancement to schedule later.

## Standards basis

- **WCAG 2.2 Level AA** (w3.org/TR/WCAG22/) — the **POUR** principles (Perceivable, Operable, Understandable, Robust) and the AA success criteria cited above: 1.4.1 (use of color), 1.4.3/1.4.11 (contrast), 2.1.1 (keyboard), 2.1.2 (no trap), 2.4.7 (focus visible), 2.5.8 (target size, new in 2.2), 4.1.2 (name/role/value). The conformance target throughout.
- **WAI-ARIA Authoring Practices Guide (APG)** (w3.org/WAI/ARIA/apg/) — the per-widget keyboard/role/state patterns behind rule 4; **WAI-ARIA 1.2** for the role/state spec and the "no ARIA is better than bad ARIA" rule (rule 1).
- **EN 301 549**, the **ADA** (DOJ web-accessibility guidance), and **Section 508** — the legal floor behind rule 6 that makes WCAG 2.2 AA a requirement, not a preference, for public services.
- **Automated-coverage limit** (axe-core / WebAIM analyses showing automation detects only a minority of WCAG issues) — the evidence for rule 2's "necessary, not sufficient."
- Builds on `03-design/ui-design-system.md` + `03-design/ui-accessibility-patterns.md` (the design contract — owned there) and `05-verification/a11y-perf-gates.md` (the automated gate — owned there). This spine adds the product-to-ops map and the manual-verification obligation automation can't enforce.

## Enforcement
- Mechanism: CI job
- Config: stacks/nextjs-default/ci/lighthouserc.json (accessibility minScore) + stacks/nextjs-default/ci/pr.yml (a11y unit checks in the test job) + stacks/nextjs-default/lint-config/biome.json (a11y markup lint) — the deterministic subset; each layer row above names its own gate.
- Fallback if unenforceable: n/a — markup-level a11y is lint/Lighthouse-gated, and the judgment pieces (keyboard operability, focus order, composite-widget contracts, perceivable state) ride the composite-widget fallback line already in `05-verification/code-review-standard.md` §E (from `03-design/ui-accessibility-patterns.md`).

## Bootstrap
- What new-project.sh injects for this standard: nothing additional — the Lighthouse accessibility gate, the a11y lint rules, and the test scaffolding it already injects are this spine's enforcement surface.
