#!/usr/bin/env bash
# metrics.sh — "state of the suite" health report (informational, never failing).
#
# Everything here is COMPUTED from the tree, never stored, so it can't drift
# (the suite's own "prefer computed over prose" discipline). Surfaces structure
# counts, calibration coverage, flow-back throughput, gate count, and whether the
# currency pass is overdue. Run it ad-hoc or at a currency pass; it is NOT part of
# the pass/fail suite-ci gate — health metrics inform, they don't block.
#
# Usage: scripts/metrics.sh [as-of-date YYYY-MM-DD]   (defaults to today)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"
TODAY="${1:-$(date +%F)}"

cd "$LIB_ROOT"

echo "=== ai-dev-standards — suite metrics (as of $TODAY) ==="
echo

# --- Structure ---------------------------------------------------------------
layer_docs=$(find 02-product 03-design 04-build 05-verification 06-delivery \
  07-operations 08-maintenance _spines -name '*.md' 2>/dev/null | wc -l | tr -d ' ')
templates=$(find . -path ./.git -prune -o -name '*.template.md' -print 2>/dev/null | wc -l | tr -d ' ')
scripts_n=$(find scripts -name '*.sh' 2>/dev/null | wc -l | tr -d ' ')
presets=$(find stacks -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
md_words=$(cat $(find . -path ./.git -prune -o -name '*.md' -print) 2>/dev/null | wc -w | tr -d ' ')
echo "Structure:"
echo "  layer docs (02-08,_spines): $layer_docs    templates: $templates    scripts: $scripts_n    stack presets: $presets"
echo "  total markdown words: $md_words"
echo

# --- Footers / gates ---------------------------------------------------------
gates=$(grep -c '^section ' scripts/suite-ci.sh 2>/dev/null || true)
echo "Enforcement:"
echo "  suite-ci sections: $gates"
echo

# --- Calibration coverage ----------------------------------------------------
cal=00-governance/calibration.md
knob_rows=$(grep -cE '^\| CAL-[A-E][0-9]+ \|' "$cal" 2>/dev/null || true)
manifest_ids=$(grep -oE '"id":"CAL-[A-E][0-9]+[a-z]?"' "$cal" 2>/dev/null | wc -l | tr -d ' ')
manifest_base=$(grep -oE '"id":"CAL-[A-E][0-9]+' "$cal" 2>/dev/null | sort -u | wc -l | tr -d ' ')
observations=$(awk '/^## Observations/{f=1;next} /^## /{f=0} f && /^\| 20[0-9][0-9]-/{c++} END{print c+0}' "$cal" 2>/dev/null)
echo "Calibration:"
echo "  knob rows: $knob_rows    manifest entries: $manifest_ids (over $manifest_base base knobs)"
echo "  machine-checked knobs: $manifest_base/$knob_rows ($(awk "BEGIN{if($knob_rows>0)printf \"%d\", 100*$manifest_base/$knob_rows; else print 0}")%)    recorded observations: $observations"
echo

# --- Flow-back throughput ----------------------------------------------------
fb=00-governance/flow-back-log.md
fb_total=$(grep -cE '^\| FB-[0-9]+ \|' "$fb" 2>/dev/null || true)
fb_patched=$(grep -cE '^\| FB-[0-9]+ \|.*\| patched \|' "$fb" 2>/dev/null || true)
fb_deferred=$(grep -cE '^\| FB-[0-9]+ \|.*\| deferred \|' "$fb" 2>/dev/null || true)
fb_nochange=$(grep -cE '^\| FB-[0-9]+ \|.*\| no-change \|' "$fb" 2>/dev/null || true)
echo "Feedback loop (cross-project findings):"
echo "  total: $fb_total    patched: $fb_patched    deferred: $fb_deferred    no-change: $fb_nochange"
echo

# --- Currency pass status ----------------------------------------------------
# Snapshot date lives in pinned-decisions.md ("currency pass YYYY-MM-DD").
snap=$(grep -oE 'currency pass 20[0-9]{2}-[0-9]{2}-[0-9]{2}' 00-governance/pinned-decisions.md 2>/dev/null | head -1 | grep -oE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' || true)
echo "Currency pass (twice-yearly floor):"
if [[ -n "$snap" ]]; then
  due=$(date -d "$snap +6 months" +%F 2>/dev/null || echo "")
  echo "  last pass: $snap    next due by: ${due:-unknown}"
  if [[ -n "$due" ]] && [[ "$TODAY" > "$due" ]]; then
    echo "  STATUS: OVERDUE as of $TODAY — run the checklist in pinned-decisions.md § Currency pass"
  else
    echo "  STATUS: current"
  fi
else
  echo "  last pass: (no 'currency pass <date>' marker found in pinned-decisions.md)"
fi
echo
echo "(informational only — not a pass/fail gate)"
