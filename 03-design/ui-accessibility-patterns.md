# UI Accessibility Patterns

Keyboard and ARIA interaction contracts for **composite widgets** — controls a browser does not supply natively (combobox, dialog, menu/menubar, tabs, disclosure, listbox). The markup-level baseline (real elements, programmatic labels, target size, query-by-role tests) lives in `03-design/ui-design-system.md` rule 8 and the gate budgets in `05-verification/a11y-perf-gates.md`; this doc adds the per-widget behavioral contract those do not — and cannot — capture. Do not re-implement a widget the platform already provides accessibly (`select`, `details`/`summary`, `dialog`): reach for ARIA only to fill a real gap (`03-design/ui-design-system.md` rule 8).

## How to read a contract

1. **First Rule of ARIA:** prefer a native element. A custom widget exists only when no native element delivers the required behavior. Once custom, it owns the **full** keyboard contract for its role — partial is non-conformant.
2. Each pattern below names its WAI-ARIA APG source. The APG pattern is the contract; this table is the index, not a substitute — implement against the linked pattern.
3. **Roving tabindex vs. `aria-activedescendant`:** a composite is **one** tab stop. Either DOM focus roves (one item `tabindex="0"`, rest `-1`) or focus stays on the container and `aria-activedescendant` points at the active descendant. Never both; never a tab stop per item.
4. Every widget satisfies WCAG 2.2 **2.1.1 Keyboard** (all functionality keyboard-operable) and **2.1.2 No Keyboard Trap** (focus can always leave) — a custom widget that swallows `Tab` or `Esc` without an exit is a defect.

## Per-widget keyboard contracts

### Disclosure — APG `patterns/disclosure/`
5. Toggle is a `button` with `aria-expanded` (`true`/`false`); `aria-controls` → the controlled region.
6. Keys: `Enter` / `Space` toggle visibility. That is the whole contract — no arrow keys.

### Dialog (modal) — APG `patterns/dialog-modal/`
7. Container `role="dialog"` (`alertdialog` for confirmations) + `aria-modal="true"` + `aria-labelledby` (or `aria-label`); `aria-describedby` optional.
8. On open: move focus **into** the dialog (first focusable, or the dialog/heading). On close: **return focus to the invoking element**.
9. Keys: `Tab` / `Shift+Tab` cycle focusable elements and **wrap within the dialog** (focus is trapped — the one legitimate trap, because `Esc` is the exit); `Esc` closes.
10. Content behind the modal is inert to AT and pointer (and visually obscured) while open. Honor 2.4.11 — the focused control is never fully hidden by sticky/overlay chrome.

### Tabs — APG `patterns/tabs/`
11. Roles: `tablist` > `tab`s; each `tab` has `aria-selected` and `aria-controls` → its `tabpanel`; each `tabpanel` has `aria-labelledby` → its tab, and `tabindex="0"` if it holds no focusable content.
12. Tab list is one tab stop (roving tabindex). Keys: `←`/`→` move between tabs (horizontal; `↑`/`↓` for vertical lists) and **wrap**; `Home`/`End` first/last (optional).
13. **Automatic activation** (selection follows focus) is the default; use **manual** activation (`Enter`/`Space` to select) only when revealing a panel is expensive. `Tab` from a tab moves into the active panel, not the next tab.

### Menu / Menubar — APG `patterns/menubar/`
14. Roles: `menubar`/`menu` containing `menuitem` (or `menuitemcheckbox`/`menuitemradio`); a parent of a submenu carries `aria-haspopup="menu"` + `aria-expanded`. This is the **application menu** pattern — not site navigation (use a `nav` + list) and not a `select` replacement (use the combobox/listbox pattern).
15. One tab stop (roving tabindex or `aria-activedescendant`). Keys: `↑`/`↓` move within a vertical menu; in a menubar `←`/`→` move between top items and `↓`/`Enter`/`Space` open a submenu; `→`/`←` open/close submenus; `Home`/`End` first/last; printable characters type-ahead; `Enter`/`Space` activate; `Esc` closes the menu and returns focus to its trigger.

### Listbox — APG `patterns/listbox/`
16. Roles: `listbox` > `option`s (`group` for sections); selection state on each option via `aria-selected` (multi-select sets `aria-multiselectable="true"` on the container). One tab stop; track the active option with roving tabindex or `aria-activedescendant`.
17. Keys (single-select): `↑`/`↓` move and select (selection follows focus); `Home`/`End`, type-ahead optional.
18. Keys (multi-select): `Space` toggles the focused option; `Shift+↑`/`Shift+↓` extend; `Ctrl+A` select-all (optional). Do not require a pointer-only modifier for any selection.

### Combobox (editable + listbox popup) — APG `patterns/combobox/`
19. Input has `role="combobox"`, `aria-expanded`, `aria-controls` → the popup, `aria-autocomplete` (`none`/`list`/`both`); the active option is referenced by `aria-activedescendant` (focus stays in the input — do **not** move DOM focus into the popup).
20. Keys: `↓` open popup / move to next option; `↑` previous (or last); `Enter` accept the focused option and close; `Esc` close popup (and on a second press clear the input, per pattern); `Alt+↓`/`Alt+↑` open/close without moving selection; printable characters edit the field. Selected option carries `aria-selected="true"`.

## Cross-cutting WCAG 2.2 obligations

21. **Focus visibility & obscuring:** every widget above shows a visible focus indicator (2.4.7) that is not fully covered by author content such as sticky headers or the widget's own overlay (2.4.11 Focus Not Obscured (Minimum), AA). Scroll the focused element into an unobscured position on open/navigation.
22. **Target size:** interactive targets in these widgets meet 2.5.8 Target Size (Minimum), AA — ≥ 24×24 CSS px, or undersized targets spaced so a 24px-diameter circle on each does not intersect another. Inherited from the token sizes in `03-design/ui-design-system.md` rule 8.
23. **State, not style:** open/selected/checked/expanded are exposed through ARIA states (`aria-expanded`, `aria-selected`, `aria-checked`), never by visual styling alone — the contract is what AT reads, not what sighted users see.

## Standards basis

- **WAI-ARIA Authoring Practices Guide (APG)** (W3C, https://www.w3.org/WAI/ARIA/apg/): the authoritative per-pattern keyboard interaction and roles/states/properties reference. Each widget section cites its pattern (`patterns/disclosure/`, `patterns/dialog-modal/`, `patterns/tabs/`, `patterns/menubar/`, `patterns/listbox/`, `patterns/combobox/`); the keys and ARIA in rules 5–20 are taken from those pages. Grounds the "one tab stop / roving tabindex vs. aria-activedescendant" rule (3, 12, 15, 16, 19) and the focus-on-open / focus-return rule for dialogs (8–9).
- **WAI-ARIA 1.2** (W3C Recommendation, 6 Jun 2023, https://www.w3.org/TR/wai-aria-1.2/): defines the roles (`dialog`, `tablist`/`tab`/`tabpanel`, `menubar`/`menu`/`menuitem`, `listbox`/`option`, `combobox`) and states/properties used throughout.
- **First Rule of ARIA Use** (ARIA in HTML / APG): "use a native element with the semantics and behavior you require" before a custom widget. Grounds rule 1 and the "don't rebuild native" guidance.
- **WCAG 2.2 Level AA** (W3C Recommendation, 12 Dec 2024, https://www.w3.org/TR/WCAG22/): **2.1.1 Keyboard (A)** and **2.1.2 No Keyboard Trap (A)** ground rule 4; **2.4.7 Focus Visible (AA)** and **2.4.11 Focus Not Obscured (Minimum) (AA)** ground rules 10 & 21; **2.5.8 Target Size (Minimum) (AA)** — ≥ 24×24 CSS px with the spacing exception — grounds rule 22 (https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum.html); **1.3.1 / 4.1.2 (Name, Role, Value)** ground the state-not-style rule 23.

## Enforcement
- Mechanism: none-possible
- Config: n/a
- Fallback if unenforceable: Every custom composite widget (combobox, dialog, menu/menubar, tabs, disclosure, listbox) implements its full APG keyboard contract — expected keys, single tab stop (roving tabindex or aria-activedescendant, not both), correct ARIA roles/states, and dialog focus trap + focus-return — verified by keyboard-only walkthrough; no native element would have sufficed.

## Bootstrap
- What new-project.sh injects for this standard: nothing — reference only (the preset's lint a11y rule set catches static markup defects per `03-design/ui-design-system.md`; the behavioral keyboard/focus contract here is verified by review, not generated).
