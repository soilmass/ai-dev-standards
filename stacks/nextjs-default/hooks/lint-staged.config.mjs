// lint-staged config — runs from the pre-commit hook.
// Biome handles lint + format + import organization in one pass.
// Scope note: Biome 1.9 formats JS/TS/JSX/JSON/CSS only — it does NOT format
// Markdown or YAML, so those are deliberately not listed here (workflow YAML
// is validated by GitHub Actions itself; doc quality rides review).
export default {
  '*.{ts,tsx,js,jsx,json,jsonc,css}': ['biome check --write --no-errors-on-unmatched'],
};
