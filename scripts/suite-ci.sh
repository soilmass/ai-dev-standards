#!/usr/bin/env bash
# suite-ci.sh — CI for the standards library itself.
#
# Runs the suite's own quality gates and accumulates findings rather than dying
# on the first failure (hard prerequisites excepted). Sections:
#
#   a. Footer audit       — delegates to scripts/audit-completeness.sh.
#   b. Script syntax      — bash -n every scripts/*.sh.
#   c. Config validity    — parse every .yml/.yaml under stacks/ and .github/,
#                           and every .json under stacks/.
#   c2. Calibration drift — every knob in 00-governance/calibration.md's machine
#                           manifest matches the value actually in the tree, and
#                           every manifest id maps to its register table row
#                           (delegates to scripts/check-calibration.sh).
#   c3. Flow-back ledger  — 00-governance/flow-back-log.md is internally consistent
#                           (ids, dispositions, patched-tag existence)
#                           (delegates to scripts/check-flowback.sh).
#   d. Internal link check— every relative markdown link target resolves.
#   e. Bootstrap smoke    — new-project.sh produces the expected artifacts and
#                           is idempotent on a second run.
#
# Exit 0 = clean; exit non-zero = failure count.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"

failures=0

# All scratch output lives under one mktemp dir registered in a single trap, so
# nothing leaks on abnormal exit and concurrent runs never clobber each other.
WORK_DIR="$(mktemp -d)"
cleanup() { rm -rf "$WORK_DIR"; }
trap cleanup EXIT

section() {
  echo
  echo "=== $1 ==="
}

fail() {
  echo "FAIL: $1"
  failures=$((failures + 1))
}

# --- a. Footer audit ---------------------------------------------------------
section "a. Footer audit (audit-completeness.sh)"
if "$LIB_ROOT/scripts/audit-completeness.sh"; then
  echo "footer audit passed"
else
  fail "audit-completeness.sh reported findings"
fi

# --- b. Script syntax --------------------------------------------------------
section "b. Script syntax (bash -n)"
for script in "$LIB_ROOT/scripts/"*.sh; do
  [[ -f "$script" ]] || continue
  rel="${script#"$LIB_ROOT"/}"
  if bash -n "$script" 2>"$WORK_DIR/bashn.err"; then
    echo "  ok   $rel"
  else
    fail "syntax error in $rel: $(cat "$WORK_DIR/bashn.err")"
  fi
done

# --- c. Config validity ------------------------------------------------------
section "c. Config validity (YAML + JSON)"

have_yaml=0
if python3 -c 'import yaml' 2>/dev/null; then
  have_yaml=1
else
  echo "  WARNING: PyYAML not available — skipping YAML validation"
fi

if [[ -d "$LIB_ROOT/stacks" || -d "$LIB_ROOT/.github" ]]; then
  while IFS= read -r -d '' yml; do
    rel="${yml#"$LIB_ROOT"/}"
    if [[ $have_yaml -eq 1 ]]; then
      if python3 -c 'import sys,yaml; list(yaml.safe_load_all(open(sys.argv[1])))' "$yml" 2>"$WORK_DIR/yaml.err"; then
        echo "  ok   $rel"
      else
        fail "invalid YAML $rel: $(cat "$WORK_DIR/yaml.err")"
      fi
    fi
  done < <(find "$LIB_ROOT/stacks" "$LIB_ROOT/.github" \( -name '*.yml' -o -name '*.yaml' \) -type f -print0 2>/dev/null)
fi

if [[ -d "$LIB_ROOT/stacks" ]]; then
  while IFS= read -r -d '' json; do
    rel="${json#"$LIB_ROOT"/}"
    if python3 -c 'import sys,json; json.load(open(sys.argv[1]))' "$json" 2>"$WORK_DIR/json.err"; then
      echo "  ok   $rel"
    else
      fail "invalid JSON $rel: $(cat "$WORK_DIR/json.err")"
    fi
  done < <(find "$LIB_ROOT/stacks" -name '*.json' -type f -print0 2>/dev/null)
fi

# --- c2. Calibration drift ----------------------------------------------------
section "c2. Calibration drift (check-calibration.sh)"
if "$LIB_ROOT/scripts/check-calibration.sh"; then
  echo "calibration register and tree agree"
else
  fail "check-calibration.sh reported drift (knob values vs 00-governance/calibration.md)"
fi

# --- c3. Flow-back ledger ----------------------------------------------------
section "c3. Flow-back ledger (check-flowback.sh)"
if "$LIB_ROOT/scripts/check-flowback.sh"; then
  echo "flow-back ledger consistent"
else
  fail "check-flowback.sh reported ledger issues (00-governance/flow-back-log.md)"
fi

# --- d. Internal link check --------------------------------------------------
section "d. Internal link check (relative markdown links)"
# Collect broken links into a report file. Run in a subshell that always exits 0
# so set -e never trips on a benign test result inside the scan loops.
LINK_REPORT="$WORK_DIR/links.out"
: > "$LINK_REPORT"
(
  while IFS= read -r -d '' md; do
    reldir="$(dirname "$md")"
    relmd="${md#"$LIB_ROOT"/}"
    # Extract link targets: [text](target). Strip the surrounding ]( ) wrapper.
    targets="$(grep -oE '\]\([^)]+\)' "$md" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' || true)"
    [[ -n "$targets" ]] || continue
    while IFS= read -r target; do
      # Drop optional link title:  (path "Title")
      target="${target%% *}"
      case "$target" in
        http://*|https://*|mailto:*|'#'*|'') continue ;;
      esac
      # Strip fragment.
      target="${target%%#*}"
      [[ -n "$target" ]] || continue
      if [[ "$target" == /* ]]; then
        resolved="$target"
      else
        resolved="$reldir/$target"
      fi
      [[ -e "$resolved" ]] || echo "$relmd -> $target" >> "$LINK_REPORT"
    done <<< "$targets"
  done < <(find "$LIB_ROOT" \( -path '*/node_modules' -o -path '*/.git' \) -prune -o -name '*.md' -type f -print0)
) || true
if [[ -s "$LINK_REPORT" ]]; then
  while IFS= read -r line; do
    fail "broken link $line"
  done < "$LINK_REPORT"
else
  echo "all relative markdown links resolve"
fi

# --- d2. Fragment anchor check ------------------------------------------------
# Section d proves the file half of every relative link resolves; it deliberately
# strips the #fragment. This section proves the OTHER half: every in-repo
# [text](file#frag) / [text](#frag) anchor names a heading that actually exists in
# the target doc (GitHub's slug algorithm). Catches the silent rot a Markdown
# renderer swallows — a link to #a-heading-that-was-renamed scrolls nowhere.
section "d2. Fragment anchor check (#targets resolve to headings)"
ANCHOR_REPORT="$WORK_DIR/anchors.out"
if python3 - "$LIB_ROOT" >"$ANCHOR_REPORT" 2>&1 <<'PYEOF'
import os, re, sys

lib_root = sys.argv[1]

INLINE_CODE = re.compile(r"`([^`]*)`")
BOLD = re.compile(r"\*\*([^*]+)\*\*")
ITAL = re.compile(r"\*([^*]+)\*")
MDLINK = re.compile(r"\[([^\]]*)\]\([^)]*\)")
NONSLUG = re.compile(r"[^\w\s-]", re.UNICODE)
HEADING = re.compile(r"^(#{1,6})\s+(.*?)\s*#*\s*$")
# [text](target) link extractor — target captured up to the first ) or whitespace.
LINK = re.compile(r"\]\(([^)\s]+)")

def slug(text):
    text = INLINE_CODE.sub(r"\1", text)
    text = BOLD.sub(r"\1", text)
    text = ITAL.sub(r"\1", text)
    text = MDLINK.sub(r"\1", text)
    text = text.strip().lower()
    text = NONSLUG.sub("", text)
    return text.replace(" ", "-")

def anchors_for(path):
    """Return the set of GitHub heading slugs in a markdown file (deduped)."""
    slugs, counts, in_fence = set(), {}, False
    try:
        lines = open(path, encoding="utf-8").read().splitlines()
    except OSError:
        return None
    for ln in lines:
        if ln.lstrip().startswith("```"):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = HEADING.match(ln)
        if not m:
            continue
        base = slug(m.group(2))
        if not base:
            continue
        n = counts.get(base, 0)
        slugs.add(base if n == 0 else f"{base}-{n}")
        counts[base] = n + 1
    return slugs

# Cache slug sets per file so a doc linked many times is parsed once.
cache = {}
def get_anchors(path):
    if path not in cache:
        cache[path] = anchors_for(path)
    return cache[path]

findings = 0
for dirpath, dirnames, filenames in os.walk(lib_root):
    dirnames[:] = [d for d in dirnames if d not in (".git", "node_modules")]
    for fn in filenames:
        if not fn.endswith(".md"):
            continue
        md = os.path.join(dirpath, fn)
        rel = os.path.relpath(md, lib_root)
        in_fence = False
        for raw in open(md, encoding="utf-8").read().splitlines():
            if raw.lstrip().startswith("```"):
                in_fence = not in_fence
                continue
            if in_fence:
                continue
            for target in LINK.findall(raw):
                if "#" not in target:
                    continue
                if target.startswith(("http://", "https://", "mailto:")):
                    continue
                filepart, frag = target.split("#", 1)
                if not frag:
                    continue
                if filepart == "":
                    tgt = md                          # same-file anchor
                elif filepart.startswith("/"):
                    tgt = lib_root + filepart
                else:
                    tgt = os.path.normpath(os.path.join(dirpath, filepart))
                if not tgt.endswith(".md"):
                    continue                          # only markdown carries heading anchors
                anchors = get_anchors(tgt)
                if anchors is None:
                    continue                          # missing file is section d's job, not ours
                if frag not in anchors:
                    print(f"{rel} -> {target} (no heading '#{frag}' in {os.path.relpath(tgt, lib_root)})")
                    findings += 1

sys.exit(1 if findings else 0)
PYEOF
then
  echo "all markdown fragment anchors resolve"
else
  if [[ -s "$ANCHOR_REPORT" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && fail "broken anchor $line"
    done < "$ANCHOR_REPORT"
  else
    fail "fragment anchor check errored (see above)"
  fi
fi

# --- e. Bootstrap smoke test -------------------------------------------------
section "e. Bootstrap smoke test (new-project.sh)"
SMOKE_DIR="$WORK_DIR/smoke"

if ! "$LIB_ROOT/scripts/new-project.sh" "$SMOKE_DIR" >"$WORK_DIR/bootstrap1.out" 2>&1; then
  fail "new-project.sh exited non-zero on first run"
  cat "$WORK_DIR/bootstrap1.out"
else
  echo "first bootstrap run completed"

  # Key artifacts that must exist and be non-empty.
  expected=(
    CLAUDE.md
    package.json
    tsconfig.json
    .env.example
    lib/db.ts
    biome.json
    .github/workflows/pr.yml
    .github/workflows/nightly.yml
    .github/workflows/release.yml
    .github/dependabot.yml
    env.schema.ts
    lighthouserc.json
    vitest.config.ts
    playwright.config.ts
    drizzle.config.ts
    next.config.ts
    instrumentation.ts
    db/schema.ts
    .gitignore
    .gitattributes
    docs/slos.md
    docs/debt-log.md
    .github/CODEOWNERS
    .github/SECURITY.md
    .github/CONTRIBUTING.md
    .github/ISSUE_TEMPLATE/bug_report.md
    .github/ISSUE_TEMPLATE/feature_request.md
    .github/ISSUE_TEMPLATE/config.yml
  )
  for artifact in "${expected[@]}"; do
    if [[ -s "$SMOKE_DIR/$artifact" ]]; then
      echo "  ok   $artifact"
    else
      fail "bootstrap artifact missing or empty: $artifact"
    fi
  done

  # The pre-commit hook must be present and executable.
  if [[ -f "$SMOKE_DIR/.husky/pre-commit" && -x "$SMOKE_DIR/.husky/pre-commit" ]]; then
    echo "  ok   .husky/pre-commit (executable)"
  else
    fail "bootstrap artifact missing or not executable: .husky/pre-commit"
  fi

  # Injected helper scripts must be executable and syntactically sound.
  for helper in setup-branch-protection.sh configure-signing.sh; do
    hp="$SMOKE_DIR/scripts/$helper"
    if [[ -f "$hp" && -x "$hp" ]] && bash -n "$hp" 2>"$WORK_DIR/helper.err"; then
      echo "  ok   scripts/$helper (executable, valid syntax)"
    else
      fail "bootstrap helper missing/not-executable/invalid: scripts/$helper $(cat "$WORK_DIR/helper.err" 2>/dev/null)"
    fi
  done

  # Derivation smoke: run the helper in DRY_RUN with a stub gh and assert it
  # actually extracts the PR job names from pr.yml (guards the indent-match bug class).
  ghstub="$WORK_DIR/ghstub"
  mkdir -p "$ghstub"
  cat > "$ghstub/gh" <<'GHEOF'
#!/usr/bin/env bash
case "$*" in
  *nameWithOwner*)    echo "smoke/repo" ;;
  *defaultBranchRef*) echo "main" ;;
esac
GHEOF
  chmod +x "$ghstub/gh"
  if ( cd "$SMOKE_DIR" && PATH="$ghstub:$PATH" DRY_RUN=1 bash scripts/setup-branch-protection.sh ) >"$WORK_DIR/bp-dry.out" 2>&1 \
       && grep -q 'Production build' "$WORK_DIR/bp-dry.out" \
       && grep -q 'required_signatures' "$WORK_DIR/bp-dry.out" \
       && grep -q 'protect-version-tags' "$WORK_DIR/bp-dry.out"; then
    echo "  ok   setup-branch-protection.sh derives checks + plans signatures + tag protection"
  else
    fail "setup-branch-protection.sh DRY_RUN missing checks/signatures/tag-protection: $(tail -n 3 "$WORK_DIR/bp-dry.out" 2>/dev/null)"
  fi

  # Conditional: only assert tests/setup.ts if the preset ships test scaffolding.
  # (Task A adds stacks/<preset>/project-config/tests/; assert only once it exists.)
  if compgen -G "$LIB_ROOT/stacks/*/project-config/tests" >/dev/null; then
    if [[ -s "$SMOKE_DIR/tests/setup.ts" ]]; then
      echo "  ok   tests/setup.ts"
    else
      fail "bootstrap artifact missing or empty: tests/setup.ts"
    fi
  else
    echo "  skip tests/setup.ts (preset ships no project-config/tests/ yet)"
  fi
fi

# Second run must be idempotent: summary reports 0 created.
if ! "$LIB_ROOT/scripts/new-project.sh" "$SMOKE_DIR" >"$WORK_DIR/bootstrap2.out" 2>&1; then
  fail "new-project.sh exited non-zero on second (idempotency) run"
  cat "$WORK_DIR/bootstrap2.out"
elif grep -qE '^Done: 0 created,' "$WORK_DIR/bootstrap2.out"; then
  echo "second run created 0 artifacts (idempotent)"
else
  fail "second run was not idempotent — summary: $(grep -E '^Done:' "$WORK_DIR/bootstrap2.out" || echo '(no summary line)')"
fi

# Every non-default preset must also bootstrap to a sound shape (multi-preset proof).
# Each preset asserts its own distinct artifacts; shared ones are covered above.
for preset_dir in "$LIB_ROOT"/stacks/*/; do
  preset="$(basename "$preset_dir")"
  [[ "$preset" == "nextjs-default" ]] && continue
  pdir="$WORK_DIR/smoke-$preset"
  if ! "$LIB_ROOT/scripts/new-project.sh" "$pdir" "$preset" >"$WORK_DIR/boot-$preset.out" 2>&1; then
    fail "new-project.sh failed for preset '$preset'"
    cat "$WORK_DIR/boot-$preset.out"
    continue
  fi
  # Every preset must yield a runnable-from-zero shape: assembled CLAUDE.md,
  # package.json + tsconfig + .env.example + DB client, lint config, PR workflow.
  for artifact in CLAUDE.md package.json tsconfig.json .env.example lib/db.ts biome.json .github/workflows/pr.yml vitest.config.ts; do
    [[ -s "$pdir/$artifact" ]] || fail "[$preset] bootstrap artifact missing/empty: $artifact"
  done
  # Container preset specifics: Prisma schema + Dockerfile + standalone next.config.
  if [[ "$preset" == "nextjs-container" ]]; then
    for artifact in prisma/schema.prisma Dockerfile next.config.ts; do
      [[ -s "$pdir/$artifact" ]] || fail "[$preset] bootstrap artifact missing/empty: $artifact"
    done
    grep -q "output: 'standalone'" "$pdir/next.config.ts" || fail "[$preset] next.config.ts lacks standalone output"
    [[ -e "$pdir/drizzle.config.ts" ]] && fail "[$preset] leaked a Drizzle config into a Prisma preset"
  fi
  echo "  ok   preset '$preset' bootstraps to a sound shape"
done

# --- f. Preset manifest coherence --------------------------------------------
# One level past "the files exist": every preset's package.json declares the
# scripts the injected workflows invoke, and its tsconfig parses. The network
# dependency-resolution proof is the scheduled preset-integration workflow's job
# (RUN_INSTALL=1); here we run the offline half.
section "f. Preset manifest coherence (check-presets.sh, no install)"
if "$LIB_ROOT/scripts/check-presets.sh" >"$WORK_DIR/presets.out" 2>&1; then
  echo "every preset's package.json scripts + tsconfig are coherent"
else
  while IFS= read -r line; do
    [[ "$line" == FAIL:* ]] && fail "${line#FAIL: }"
  done < "$WORK_DIR/presets.out"
  [[ -s "$WORK_DIR/presets.out" ]] && sed 's/^/    /' "$WORK_DIR/presets.out"
fi

# --- summary -----------------------------------------------------------------
echo
if [[ $failures -eq 0 ]]; then
  echo "OK: suite CI passed — footers, script syntax, config validity, calibration register, flow-back ledger, internal links, fragment anchors, bootstrap smoke test, and preset manifest coherence all clean."
else
  echo "FAIL: $failures finding(s). Fix the reported issues above."
  exit 1
fi
