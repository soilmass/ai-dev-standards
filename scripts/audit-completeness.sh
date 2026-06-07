#!/usr/bin/env bash
# audit-completeness.sh — the executable form of 00-governance/completeness-matrix.md.
#
# Checks that every layer doc (02-product .. 08-maintenance, _spines) carries the
# required Enforcement/Bootstrap footer:
#
#   ## Enforcement
#   - Mechanism: <lint rule | CI job | git hook | runtime check | none-possible>
#   - Config: ...
#   - Fallback if unenforceable: ...   (REQUIRED when Mechanism is none-possible)
#
#   ## Bootstrap
#   - ...
#
# Additionally verifies the aggregation rule: every none-possible doc's Fallback
# line appears VERBATIM in 05-verification/code-review-standard.md.
#
# Exit 0 = complete; exit 1 = findings (each printed with file + reason).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"
CHECKLIST="$LIB_ROOT/05-verification/code-review-standard.md"

LAYERS=(02-product 03-design 04-build 05-verification 06-delivery 07-operations 08-maintenance _spines)
VALID_MECHANISMS='lint rule|CI job|git hook|runtime check|none-possible'

failures=0
checked=0

fail() {
  echo "MISSING: $1 — $2"
  failures=$((failures + 1))
}

for layer in "${LAYERS[@]}"; do
  for doc in "$LIB_ROOT/$layer"/*.md; do
    [[ -f "$doc" ]] || continue
    rel="${doc#"$LIB_ROOT"/}"
    checked=$((checked + 1))

    grep -q '^## Enforcement$' "$doc" || { fail "$rel" "no '## Enforcement' heading"; continue; }
    grep -q '^## Bootstrap$'   "$doc" || { fail "$rel" "no '## Bootstrap' heading"; continue; }

    mechanism="$(grep -m1 '^- Mechanism: ' "$doc" | sed 's/^- Mechanism: //' || true)"
    if [[ -z "$mechanism" ]]; then
      fail "$rel" "no '- Mechanism:' line under Enforcement"
      continue
    fi
    if ! grep -qE "^- Mechanism: ($VALID_MECHANISMS)" "$doc"; then
      fail "$rel" "mechanism '$mechanism' not one of: lint rule | CI job | git hook | runtime check | none-possible"
    fi

    grep -q '^- Config: ' "$doc" || fail "$rel" "no '- Config:' line under Enforcement"

    if [[ "$mechanism" == "none-possible" ]]; then
      fallback="$(grep -m1 '^- Fallback if unenforceable: ' "$doc" | sed 's/^- Fallback if unenforceable: //' || true)"
      if [[ -z "$fallback" ]]; then
        fail "$rel" "mechanism is none-possible but no Fallback line"
      elif ! grep -qF "$fallback" "$CHECKLIST"; then
        fail "$rel" "none-possible fallback not found VERBATIM in 05-verification/code-review-standard.md: '$fallback'"
      fi
    fi

    # Bootstrap section must contain at least one content bullet after the heading
    if ! awk '/^## Bootstrap$/{found=1; next} found && /^- /{ok=1} END{exit !ok}' "$doc"; then
      fail "$rel" "Bootstrap section has no content bullet"
    fi
  done
done

echo
if [[ $failures -eq 0 ]]; then
  echo "OK: $checked layer docs checked, all carry the Enforcement/Bootstrap footer (and none-possible fallbacks are aggregated)."
else
  echo "FAIL: $failures finding(s) across $checked docs. Fix the footers (root CLAUDE.md §1), then update 00-governance/completeness-matrix.md."
  exit 1
fi
