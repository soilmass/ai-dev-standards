#!/usr/bin/env bash
# Enforcement-integrity guard — run in CI on every PR (and locally if you like).
# Fails if a safety gate was WEAKENED to make a check pass — the classic agent
# cheat: disable strict typing, turn off a safety lint, or zero the coverage gate.
# It asserts the enforcement FLOOR is intact: raising a gate is fine; lowering or
# removing one fails here. Backs the agent never-touch rule
# (00-governance/agent-operating-rules.md §3) and 05-verification/ci-pipeline.md.
# Run from the project root:  bash scripts/check-enforcement.sh
set -uo pipefail

fail=0
violate() { echo "  ✗ $1" >&2; fail=1; }

ts="tsconfig.json"
biome="biome.json"
vitest="$(ls vitest.config.* 2>/dev/null | head -n1 || true)"

# 1. TypeScript strictness must stay on.
if [[ -f "$ts" ]]; then
  grep -Eq '"strict"[[:space:]]*:[[:space:]]*true' "$ts" \
    || violate "tsconfig: \"strict\": true is missing or disabled"
  grep -Eq '"noUncheckedIndexedAccess"[[:space:]]*:[[:space:]]*true' "$ts" \
    || violate "tsconfig: \"noUncheckedIndexedAccess\": true is missing or disabled"
else
  violate "tsconfig.json not found"
fi

# 2. Safety lint rules must stay at "error" (not "off"/"warn"/removed).
if [[ -f "$biome" ]]; then
  for rule in noExplicitAny noNonNullAssertion noFocusedTests noSkippedTests; do
    grep -Eq "\"$rule\"[[:space:]]*:[[:space:]]*\"error\"" "$biome" \
      || violate "biome: rule \"$rule\" is not set to \"error\" (disabled or downgraded)"
  done
else
  violate "biome.json not found"
fi

# 3. The coverage gate must exist and not be zeroed out.
if [[ -n "${vitest:-}" && -f "$vitest" ]]; then
  grep -q 'thresholds' "$vitest" || violate "$vitest: coverage thresholds block removed"
  if grep -Eq '(lines|functions|branches|statements):[[:space:]]*0([^0-9]|$)' "$vitest"; then
    violate "$vitest: a coverage threshold is set to 0 (gate disabled)"
  fi
else
  echo "  · no vitest config found — skipping coverage check" >&2
fi

if [[ "$fail" -ne 0 ]]; then
  echo "" >&2
  echo "ENFORCEMENT-GUARD FAILED: an enforcement gate was weakened. Restore it, or land the" >&2
  echo "change as its own reviewed PR with a stated reason (agent never-touch rule §3)." >&2
  exit 1
fi
echo "enforcement floor intact — tsconfig strict, safety lints at error, coverage gate present"
