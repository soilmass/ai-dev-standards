#!/usr/bin/env bash
# check-presets.sh — preset integration check, one level deeper than the
# syntactic bootstrap smoke in suite-ci.sh.
#
# The smoke test proves the right files land in the right place. This proves the
# package manifests a bootstrapped project receives are internally COHERENT and
# installable-from-zero:
#
#   1. package.json parses and declares every script the injected CI workflows
#      invoke (lint, typecheck, test, build) — a workflow that runs `pnpm test`
#      against a package.json with no `test` script is a real bootstrap bug the
#      file-existence smoke can't see.
#   2. tsconfig.json parses.
#   3. (Opt-in: RUN_INSTALL=1, needs network + a package manager) a real install
#      resolves the pinned dependency set, proving the peer graph is internally
#      consistent — the FB-01 class of bug (a fresh install hitting a peer
#      mismatch). Note: this checks DEPENDENCY RESOLUTION, not a full `next build`;
#      a build also needs the app shell (app/layout.tsx, app/page.tsx) the operator
#      scaffolds per CLAUDE.md's setup walkthrough — the documented guided step.
#
# Default (no RUN_INSTALL) needs no network and is wired into suite CI. The
# scheduled .github/workflows/preset-integration.yml sets RUN_INSTALL=1.
#
# Exit 0 = clean; exit non-zero = finding count.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"

RUN_INSTALL="${RUN_INSTALL:-0}"
REQUIRED_SCRIPTS=(lint typecheck test build)

failures=0
fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

if [[ ! -d "$LIB_ROOT/stacks" ]]; then
  echo "no stacks/ directory — nothing to check"
  exit 0
fi

for preset_dir in "$LIB_ROOT"/stacks/*/; do
  [[ -d "$preset_dir" ]] || continue
  preset="$(basename "$preset_dir")"
  echo
  echo "=== preset: $preset ==="

  pdir="$WORK_DIR/$preset"
  if ! "$LIB_ROOT/scripts/new-project.sh" "$pdir" "$preset" >"$WORK_DIR/boot-$preset.out" 2>&1; then
    fail "$preset: new-project.sh failed"
    cat "$WORK_DIR/boot-$preset.out"
    continue
  fi

  pkg="$pdir/package.json"
  if [[ ! -s "$pkg" ]]; then
    fail "$preset: bootstrap produced no package.json"
    continue
  fi

  # 1 + 2: manifest coherence (package.json scripts present; tsconfig parses).
  if python3 - "$pkg" "$pdir/tsconfig.json" "${REQUIRED_SCRIPTS[@]}" >"$WORK_DIR/pkg-$preset.out" 2>&1 <<'PYEOF'
import json, sys

pkg_path, tsconfig_path = sys.argv[1], sys.argv[2]
required = sys.argv[3:]
findings = 0

def finding(msg):
    global findings
    findings += 1
    print(msg)

try:
    pkg = json.load(open(pkg_path, encoding="utf-8"))
except (OSError, ValueError) as e:
    print(f"package.json does not parse: {e}")
    sys.exit(1)

scripts = pkg.get("scripts", {})
for name in required:
    if name not in scripts:
        finding(f"package.json missing required script '{name}' (an injected CI workflow invokes it)")

if not pkg.get("dependencies") and not pkg.get("devDependencies"):
    finding("package.json declares no dependencies or devDependencies")

# tsconfig must parse. It may be JSONC (comments) — strip them string-safely
# so values containing /* or */ (e.g. "@/*", "**/*.ts") aren't mistaken for
# comment delimiters, which a naive regex would do.
def strip_jsonc(s):
    """Remove // and /* */ comments, ignoring anything inside string literals."""
    out, i, n, in_str, esc = [], 0, len(s), False, False
    while i < n:
        c = s[i]
        if in_str:
            out.append(c)
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
            i += 1
        elif c == '"':
            in_str = True
            out.append(c)
            i += 1
        elif c == "/" and i + 1 < n and s[i + 1] == "/":
            i += 2
            while i < n and s[i] != "\n":
                i += 1
        elif c == "/" and i + 1 < n and s[i + 1] == "*":
            i += 2
            while i + 1 < n and not (s[i] == "*" and s[i + 1] == "/"):
                i += 1
            i += 2
        else:
            out.append(c)
            i += 1
    return "".join(out)

try:
    json.loads(strip_jsonc(open(tsconfig_path, encoding="utf-8").read()))
except OSError:
    finding("tsconfig.json missing")
except ValueError as e:
    finding(f"tsconfig.json does not parse: {e}")

if findings == 0:
    print(f"  ok   package.json scripts {required} present; tsconfig.json parses")
sys.exit(1 if findings else 0)
PYEOF
  then
    cat "$WORK_DIR/pkg-$preset.out"
  else
    while IFS= read -r line; do
      [[ -n "$line" ]] && fail "$preset: $line"
    done < "$WORK_DIR/pkg-$preset.out"
  fi

  # 3: optional real install — dependency-resolution proof (needs network).
  if [[ "$RUN_INSTALL" == "1" ]]; then
    if command -v pnpm >/dev/null 2>&1; then
      echo "  RUN_INSTALL=1 → resolving dependency graph with pnpm (no scripts)…"
      if ( cd "$pdir" && pnpm install --ignore-scripts >"$WORK_DIR/install-$preset.out" 2>&1 ); then
        echo "  ok   dependency set resolves cleanly"
      else
        fail "$preset: pnpm install failed to resolve the pinned dependency set"
        tail -n 40 "$WORK_DIR/install-$preset.out"
      fi
    else
      echo "  skip install proof — pnpm not on PATH"
    fi
  else
    echo "  skip install proof (set RUN_INSTALL=1 to resolve the dependency graph)"
  fi
done

echo
if [[ $failures -eq 0 ]]; then
  echo "OK: all presets bootstrap to a coherent shape (RUN_INSTALL=$RUN_INSTALL)."
else
  echo "FAIL: $failures finding(s)."
  exit 1
fi
