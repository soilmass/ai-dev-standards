#!/usr/bin/env bash
# check-flowback.sh — integrity of the cross-project flow-back ledger.
#
# Validates 00-governance/flow-back-log.md (the library's memory of project
# findings). Checks, accumulating findings rather than dying on the first:
#   - FB ids are unique and sequential (FB-01, FB-02, ...);
#   - disposition is one of: patched | deferred | no-change;
#   - every `patched` row names a tag that actually exists in `git tag`
#     (a "fixed" claim cannot outrun the release that shipped it);
#   - every `deferred` row carries a non-empty revisit trigger (the Tag/commit
#     cell is used for the trigger when deferred — must not be empty/placeholder).
#
# Exit 0 = consistent; exit 1 = violations (each printed).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"
LEDGER="$LIB_ROOT/00-governance/flow-back-log.md"

if [[ ! -f "$LEDGER" ]]; then
  echo "FAIL: flow-back ledger not found: $LEDGER" >&2
  exit 1
fi

# Tag list (empty string if not a git repo — patched-tag check then fails loudly,
# which is correct: a patched claim needs a real tag).
tags="$(cd "$LIB_ROOT" && git tag 2>/dev/null || true)"

python3 - "$LEDGER" "$tags" <<'PYEOF'
import re, sys

ledger = open(sys.argv[1], encoding="utf-8").read()
tags = set(t.strip() for t in sys.argv[2].splitlines() if t.strip())

# Data rows: lines starting with "| FB-" inside the table.
rows = [ln for ln in ledger.splitlines() if re.match(r"\s*\|\s*FB-\d+\s*\|", ln)]
failures = 0
seen_ids = []

def fail(msg):
    global failures
    failures += 1
    print(f"FLOWBACK {msg}")

for ln in rows:
    cells = [c.strip() for c in ln.strip().strip("|").split("|")]
    # columns: ID | Surfaced | Source | Finding | Disposition | Tag/commit | Status
    if len(cells) < 7:
        fail(f"row has {len(cells)} cells, expected 7: {cells[0] if cells else '?'}")
        continue
    fid, _surfaced, source, _finding, disposition, tagcell, _status = cells[:7]
    seen_ids.append(fid)
    if not source:
        fail(f"{fid}: empty source project")
    if disposition not in ("patched", "deferred", "no-change"):
        fail(f"{fid}: disposition '{disposition}' not in patched|deferred|no-change")
    if disposition == "patched":
        # tagcell should be a tag that exists
        if not tagcell:
            fail(f"{fid}: patched but no tag named")
        elif tags and tagcell not in tags:
            fail(f"{fid}: patched names tag '{tagcell}' which is not in git tag")
    if disposition == "deferred" and not tagcell:
        fail(f"{fid}: deferred but no revisit trigger in the Tag/commit cell")

# Unique + sequential
nums = []
for fid in seen_ids:
    m = re.match(r"FB-0*(\d+)", fid)
    if m:
        nums.append(int(m.group(1)))
if len(set(seen_ids)) != len(seen_ids):
    fail(f"duplicate FB ids among {seen_ids}")
if nums and nums != list(range(1, len(nums) + 1)):
    fail(f"FB ids not sequential from 1: {nums}")

print()
if failures:
    print(f"FAIL: {failures} flow-back ledger issue(s) across {len(rows)} entries.")
    sys.exit(1)
print(f"OK: flow-back ledger consistent — {len(rows)} entries, all dispositions valid.")
PYEOF
