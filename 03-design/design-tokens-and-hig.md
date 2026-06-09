# Design Tokens & Platform-Guideline Grounding

The design layer is not invented per project — it is **grounded in named external authorities** and the project's choices are recorded as deviations from them, not as free-floating taste. This doc names those authorities (W3C Design Tokens, Apple HIG, Material Design 3, WAI-ARIA APG), fixes the **token taxonomy** every project's styling system must populate, and sets the **borrow-vs-reject discipline** for when a platform convention is adopted on the web and when web norms override it. The styling-system *config* that holds the tokens is a stack choice named in the preset; the structural component rules that consume tokens live in `03-design/ui-design-system.md` (rules 1–3) and the keyboard/role contracts in `03-design/ui-accessibility-patterns.md`. This doc is the *grounding* — why the tokens are shaped the way they are and which guideline a given design decision answers to.

## The named authorities

A design decision in this suite cites one of these by section. "It looks better" is not a rationale; "follows MD3 *state layers* for the hover/pressed treatment" is.

1. **W3C Design Tokens (DTCG)** — the Design Tokens Community Group Format Module (first stable version Oct 2025; `.tokens` / `application/design-tokens+json`). The vendor-neutral interchange format and **type taxonomy** for tokens: `color`, `dimension` (spacing/sizing), `fontFamily`/`fontWeight`/`typography` (composite), `duration`/`cubicBezier` (motion), `border`, `shadow`, plus **groups** and **aliases** (`{group.token}` references). This is the authority for *how tokens are named and shaped* — not which colors.
2. **Apple Human Interface Guidelines (HIG)** — Apple's platform guidance (`developer.apple.com/design/human-interface-guidelines/`). The authority for native-feel conventions on Apple platforms: touch-target minimums, the Dynamic Type scale, system materials/vibrancy, gesture and navigation idioms, and the platform's accessibility commitments.
3. **Material Design 3 (MD3)** — Google's design system (`m3.material.io`). The authority for a token-first design system in practice: the **color-role system** (primary/secondary/tertiary + on-color pairs, surface tiers), the **type scale** (display/headline/title/body/label), **elevation/state-layer** model, **shape** scale, and motion/easing tokens. MD3 is itself expressed as design tokens, so it is the worked reference for the DTCG taxonomy above.
4. **WAI-ARIA Authoring Practices Guide (APG)** — W3C (`www.w3.org/WAI/ARIA/apg/`). The authority for interaction behavior: roles, states, and the per-widget keyboard contract. The web-platform accessibility floor (WCAG 2.2 AA) and the per-widget contracts already live in `03-design/ui-design-system.md` rule 8 and `03-design/ui-accessibility-patterns.md`; this doc adds only that a design decision affecting an interactive pattern must name the APG pattern it implements (e.g. `patterns/disclosure/`), the same way a visual decision names its HIG/MD3 section.

## Token taxonomy — defined once, referenced everywhere

5. Every project's styling system defines tokens covering, at minimum, the **DTCG-aligned token groups** below. A group present in the design but absent from the token set is an incompleteness, not an omission to defer:
   - **color** — semantic roles (not raw swatches): surface/background, foreground/on-surface, primary + on-primary, border, and feedback (success/warning/error/info). Raw palette values exist only as the *base* layer that semantic roles alias.
   - **dimension — spacing** — a single spacing scale (a stepped ramp), referenced for padding/margin/gap; no off-scale pixel values in components.
   - **dimension — sizing & radii** — control sizes (so interactive-primitive sizes never drop below the WCAG 2.2 **2.5.8** 24×24 CSS-px floor per `03-design/ui-design-system.md` rule 8) and a corner-radius scale.
   - **typography** — a type scale (size + line-height + weight as composite tokens), font-family tokens, and weight tokens.
   - **motion** — duration and easing (`cubicBezier`) tokens; transitions reference these, not inline literals.
   - **elevation/shadow** and **border** — shadow tokens for layering and border-width/style tokens.
6. **Tokens are defined once and aliased, never duplicated.** Semantic tokens reference base tokens via DTCG aliases (`{color.base.blue.600}`); components reference **semantic** tokens only. A component that reaches past the semantic layer to a base palette value couples itself to a swatch and breaks theming.
7. **No bare hex, no magic numbers in component code.** A raw `#rrggbb`/`rgb()`/`hsl()` literal, an off-scale `13px`, or an inline `cubic-bezier(...)` in a component is a violation — it is a token that was never named. This is the consuming consequence of `03-design/ui-design-system.md` rule 2; the markup/styling side is lint- and review-gated there, and the token-completeness + no-bare-hex judgment rides the self-review fallback below (no general-purpose linter reliably distinguishes a legitimate raw color in a token-definition file from a stray one in a component, so this is review-carried, not falsely claimed as lint-enforced).
8. **Theming (dark mode, brand variants) works through token aliasing**, never per-component conditionals — the same rule as `03-design/ui-design-system.md` rule 3, restated here as a token-layer obligation: a theme is a different binding of semantic tokens to base values, not a fork of component logic.

## Borrow-vs-reject discipline

A platform guideline (HIG, MD3) is written for *its* platform. On the web you **borrow the principle, not the chrome** — and you record which. The test for each decision:

9. **BORROW** a platform convention when it encodes a durable interaction or perception principle that holds on the web:
   - HIG/MD3 **touch-target minimums** → adopt; they reinforce WCAG 2.2 2.5.8 (`03-design/ui-design-system.md` rule 8).
   - MD3 **token-first structure** (semantic color roles, a single type scale, state layers, an elevation model) → adopt as the shape of the token set (rule 5).
   - HIG/MD3 **content hierarchy, spacing rhythm, and motion-with-purpose** (motion communicates state change, respects reduced-motion) → adopt as principles.
   - APG **roles/states/keyboard contracts** → adopt verbatim; these *are* the web behavior (`03-design/ui-accessibility-patterns.md`).
10. **REJECT / override** a platform convention when a web norm governs instead:
    - **Native-only chrome** (iOS tab bars, Android back-button behavior, platform system fonts/materials, page-sheet presentations) → do not transplant pixel-for-pixel onto the web; use the web-native equivalent.
    - **Platform navigation idioms** that conflict with web expectations (browser back/forward, addressable URLs, real `<a>` links) → web norms win; an in-page gesture that breaks the back button is rejected.
    - **Reachability/hit-target rules tuned to a thumb on a phone** on a pointer-and-keyboard surface → re-derive from the web a11y floor, do not copy the phone layout.
    - Where a guideline conflicts with **WCAG 2.2 AA**, accessibility wins — always (`03-design/ui-design-system.md` rule 8).
11. **Every non-trivial design decision cites its authority + section, and a borrow/reject decision is recorded** (in the component's notes, the PR description, or an ADR per `01-context/adr.template.md` when it sets a standing pattern). The citation names the specific section (e.g. "MD3 *state layers*", "HIG *Layout → Adaptivity and Layout*", "APG `patterns/combobox/`"), so a reviewer can check the decision against the source rather than against opinion. An uncited visual or interaction decision is treated as ungrounded and sent back.

## Standards basis

- **W3C Design Tokens Format Module** (DTCG, first stable version Oct 2025; `.tokens` / `application/design-tokens+json`): the vendor-neutral token interchange format — typed tokens (`color`, `dimension`, `fontFamily`, `typography`, `duration`, `cubicBezier`, `border`, `shadow`), groups, and `{alias}` references. Grounds the token taxonomy (rule 5), the alias-don't-duplicate rule (6), and theming-via-aliasing (8). Shared with `03-design/ui-design-system.md` rule 2, which states the consuming component rule; this doc fixes the producing taxonomy.
- **Material Design 3** (Google, https://m3.material.io): a production token-first design system — semantic color roles + on-color pairs, the type scale, state layers, elevation, shape, and motion tokens — used as the worked reference for the DTCG taxonomy and as a primary BORROW source for token structure (rules 5, 9).
- **Apple Human Interface Guidelines** (Apple, https://developer.apple.com/design/human-interface-guidelines/): platform guidance for native-feel conventions (target sizes, Dynamic Type, materials, navigation/gesture idioms, accessibility). Grounds the BORROW list (target minimums, hierarchy, purposeful motion — rule 9) and the REJECT list (native-only chrome and navigation idioms that conflict with web norms — rule 10).
- **WAI-ARIA Authoring Practices Guide (APG)** (W3C, https://www.w3.org/WAI/ARIA/apg/): the authoritative per-pattern roles/states/keyboard reference. Grounds the requirement that an interaction-affecting design decision cite its APG pattern (rule 4, 9); the per-widget contracts themselves are in `03-design/ui-accessibility-patterns.md`.
- **WCAG 2.2 Level AA** (W3C Recommendation, 12 Dec 2024, https://www.w3.org/TR/WCAG22/): the accessibility floor that overrides any platform guideline in conflict (rule 10) and fixes the 2.5.8 Target Size minimum that sizing tokens must respect (rule 5). The full a11y baseline lives in `03-design/ui-design-system.md` rule 8 and `05-verification/a11y-perf-gates.md`.

## Enforcement
- Mechanism: none-possible
- Config: stacks/nextjs-default/lint-config/biome.json (the a11y/markup baseline that backs the token-consuming rules) — but the token-taxonomy completeness, no-bare-hex-in-components judgment, the borrow/reject decision, and the HIG/MD3/APG citation are not mechanically checkable and are review-carried via the fallback below.
- Fallback if unenforceable: Tokens cover the DTCG groups (color roles, spacing, sizing/radii, typography, motion, elevation/border) and are defined once and aliased — no bare hex or magic numbers in components; and every non-trivial visual/interaction decision cites the specific HIG / Material 3 / WAI-ARIA APG section it follows, recording any platform convention borrowed or rejected (web a11y norms override the platform on conflict).

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the styling-system config the preset names is where a project defines its actual tokens; this doc grounds their shape and the citation discipline, which are verified by review, not generated).
