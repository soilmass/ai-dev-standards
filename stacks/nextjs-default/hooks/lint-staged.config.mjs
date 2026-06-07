// lint-staged config — runs from the pre-commit hook.
// Biome handles lint + format + import organization in one pass per file set.
export default {
  '*.{ts,tsx,js,jsx,json,jsonc,css}': ['biome check --write --no-errors-on-unmatched'],
  '*.{md,yml,yaml}': ['biome format --write --no-errors-on-unmatched'],
};
