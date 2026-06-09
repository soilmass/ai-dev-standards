#!/usr/bin/env bash
# check-calibration.sh — the executable side of 00-governance/calibration.md.
#
# The calibration register documents every tunable knob with its value, rationale,
# and recalibration trigger. This script verifies the register and reality agree:
# it extracts the machine manifest (the ```json calibration-manifest fenced block
# in calibration.md), resolves each entry against the actual file, and compares.
#
# Manifest entry shapes:
#   {"id":"CAL-xx","file":"<repo-relative>","kind":"json","path":"a.b.0.c","expect":"<value>"}
#   {"id":"CAL-xx","file":"<repo-relative>","kind":"regex","pattern":"<re with ONE capture group>","expect":"<value>"}
# (kind "regex" works on any text file incl. YAML and markdown — the capture
#  group is the knob's value as written in that file.)
#
# Exit 0 = register and tree agree; exit 1 = drift or unresolvable locator,
# each reported as: DRIFT <id>: <file> says '<actual>', register expects '<expect>'.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"
REGISTER="$LIB_ROOT/00-governance/calibration.md"

if [[ ! -f "$REGISTER" ]]; then
  echo "FAIL: register not found: $REGISTER" >&2
  exit 1
fi

python3 - "$LIB_ROOT" "$REGISTER" <<'PYEOF'
import json, re, sys

lib_root, register = sys.argv[1], sys.argv[2]
text = open(register, encoding="utf-8").read()

m = re.search(r"```json calibration-manifest\n(.*?)\n```", text, re.DOTALL)
if not m:
    print("FAIL: no ```json calibration-manifest block in calibration.md")
    sys.exit(1)

try:
    manifest = json.loads(m.group(1))
except json.JSONDecodeError as e:
    print(f"FAIL: manifest block is not valid JSON: {e}")
    sys.exit(1)

failures = 0
checked = 0

def fail(entry, msg):
    global failures
    failures += 1
    print(f"DRIFT {entry.get('id','?')}: {msg}")

for entry in manifest:
    checked += 1
    eid, fname, kind, expect = entry.get("id"), entry.get("file"), entry.get("kind"), str(entry.get("expect"))
    try:
        content = open(f"{lib_root}/{fname}", encoding="utf-8").read()
    except OSError:
        fail(entry, f"{fname} — file missing or unreadable")
        continue

    if kind == "json":
        try:
            node = json.loads(content)
            for part in entry["path"].split("."):
                node = node[int(part)] if isinstance(node, list) else node[part]
            if isinstance(node, (dict, list)):
                fail(entry, f"{fname} — JSON path '{entry.get('path')}' resolved to a {type(node).__name__}, not a scalar (path too short or mistyped)")
                continue
            actual = str(node)
        except (KeyError, IndexError, ValueError, TypeError):
            fail(entry, f"{fname} — JSON path '{entry.get('path')}' did not resolve")
            continue
    elif kind == "regex":
        mm = re.search(entry["pattern"], content)
        if not mm:
            fail(entry, f"{fname} — pattern not found: {entry['pattern']!r}")
            continue
        if mm.lastindex is None:
            fail(entry, f"{fname} — pattern has no capture group: {entry['pattern']!r}")
            continue
        actual = mm.group(1)
    else:
        fail(entry, f"unknown kind '{kind}'")
        continue

    if actual != expect:
        fail(entry, f"{fname} says '{actual}', register expects '{expect}'")

# --- Coherence: every manifest id maps to its register table row -------------
# Kills the round-3 bug class (manifest CAL-Xnn pointing at a knob that table row
# CAL-Xnn does NOT describe). For each manifest entry, the base id (suffix a/b/c
# stripped) must exist as a table row whose `Where` column names the entry's file.
import os

# Table rows: first cell is the CAL id (Observations rows start with a date, so
# they don't match — only knob-definition rows do).
rows = {}
for ln in text.splitlines():
    rm = re.match(r"\s*\|\s*(CAL-[A-E]\d+)\s*\|(.*)$", ln)
    if rm:
        cells = [c.strip() for c in rm.group(2).split("|")]
        # remaining cells after the id: Knob | Value | Where | ...
        where = cells[2] if len(cells) >= 3 else ""
        rows[rm.group(1)] = where

coherence = 0
def cfail(msg):
    global coherence
    coherence += 1
    print(f"COHERENCE {msg}")

for entry in manifest:
    eid = entry.get("id", "?")
    base = re.sub(r"[a-z]+$", "", eid)  # CAL-C09c -> CAL-C09
    if base not in rows:
        cfail(f"{eid}: no register table row '{base}'")
        continue
    basename = os.path.basename(entry.get("file", ""))
    if basename and basename not in rows[base]:
        cfail(f"{eid}: target '{basename}' not named in row {base}'s Where column "
              f"(row points elsewhere — id/knob mismatch)")

# --- Inventory: tracked-files block must equal the manifest's file set -------
# Stops a new calibrated knob sneaking in uncalibrated: the ```calibration-tracked-files
# block is the declared inventory of every file the manifest reads; it must match
# the actual set of manifested files exactly (both directions), and each must exist.
inventory = 0
def ifail(msg):
    global inventory
    inventory += 1
    print(f"INVENTORY {msg}")

im = re.search(r"```calibration-tracked-files\n(.*?)\n```", text, re.DOTALL)
if not im:
    ifail("no ```calibration-tracked-files block in calibration.md")
    declared = set()
else:
    declared = {ln.strip() for ln in im.group(1).splitlines() if ln.strip()}

manifested = {e.get("file") for e in manifest if e.get("file")}
for f in sorted(manifested - declared):
    ifail(f"{f}: read by the manifest but absent from the tracked-files inventory")
for f in sorted(declared - manifested):
    ifail(f"{f}: listed in tracked-files but no manifest entry reads it")
for f in sorted(declared):
    if not os.path.exists(f"{lib_root}/{f}"):
        ifail(f"{f}: listed in tracked-files but missing on disk")

print()
if failures or coherence or inventory:
    if failures:
        print(f"FAIL: {failures} drifted/unresolvable of {checked} calibration entries.")
    if coherence:
        print(f"FAIL: {coherence} manifest↔row coherence issue(s).")
    if inventory:
        print(f"FAIL: {inventory} tracked-files inventory mismatch(es).")
    print("Re-align the file and 00-governance/calibration.md in the same commit.")
    sys.exit(1)
print(f"OK: {checked} calibration entries verified — values agree, every manifest id maps to its row, "
      f"and the tracked-files inventory matches the manifest ({len(declared)} files).")
PYEOF
