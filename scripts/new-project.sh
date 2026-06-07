#!/usr/bin/env bash
# new-project.sh — bootstrap a new project from this standards library.
#
# Usage: scripts/new-project.sh <target-directory> [stack-preset]
#   <target-directory>  where to bootstrap (created if missing)
#   [stack-preset]      a directory name under stacks/ (default: nextjs-default)
#
# What it does:
#   1. Assembles <target>/CLAUDE.md from 01-context/CLAUDE.template.md + the
#      preset's CLAUDE.partial.md (stamping preset name + date).
#   2. Copies the preset's known-good configs: lint-config/*, ci/* -> .github/workflows
#      (+ ci config files -> project root), hooks/* -> .husky + config files,
#      dependabot.yml -> .github/, env.schema.example -> env.schema.ts.
#   3. Drops the working templates into <target>/docs/.
#
# Idempotent: existing files are never overwritten; they are reported and skipped.
# Re-running after you've edited files is safe.

set -euo pipefail

# --- locate ourselves -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_ROOT="$(dirname "$SCRIPT_DIR")"

# --- args -------------------------------------------------------------------
if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <target-directory> [stack-preset]" >&2
  exit 1
fi

TARGET="$1"
PRESET="${2:-nextjs-default}"
PRESET_DIR="$LIB_ROOT/stacks/$PRESET"

if [[ ! -d "$PRESET_DIR" ]]; then
  echo "ERROR: unknown stack preset '$PRESET' — available presets:" >&2
  find "$LIB_ROOT/stacks" -mindepth 1 -maxdepth 1 -type d -printf '  %f\n' >&2
  exit 1
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

created=0
skipped=0

# install <source-file> <dest-path> [mode]
install_file() {
  local src="$1" dest="$2" mode="${3:-}"
  if [[ -e "$dest" ]]; then
    echo "  skip   ${dest#"$TARGET"/} (already exists)"
    skipped=$((skipped + 1))
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  cp "$src" "$dest"
  [[ -n "$mode" ]] && chmod "$mode" "$dest"
  echo "  create ${dest#"$TARGET"/}"
  created=$((created + 1))
}

echo "Bootstrapping '$TARGET' with preset '$PRESET'"
echo "Library: $LIB_ROOT"
echo

# --- 1. assemble CLAUDE.md ---------------------------------------------------
echo "[1/3] Project CLAUDE.md"
if [[ -e "$TARGET/CLAUDE.md" ]]; then
  echo "  skip   CLAUDE.md (already exists)"
  skipped=$((skipped + 1))
else
  {
    sed -e "s|<STACK_PRESET>|$PRESET|g" \
        -e "s|<BOOTSTRAP_DATE>|$(date -u +%Y-%m-%d)|g" \
        -e "s|<STANDARDS_PATH>|$LIB_ROOT|g" \
        "$LIB_ROOT/01-context/CLAUDE.template.md"
    echo
    cat "$PRESET_DIR/CLAUDE.partial.md"
  } > "$TARGET/CLAUDE.md"
  echo "  create CLAUDE.md (template + $PRESET partial; fill remaining <ANGLE_BRACKET> blanks)"
  created=$((created + 1))
fi

# --- 2. copy preset configs --------------------------------------------------
echo "[2/3] Preset configs"

# lint config -> project root
for f in "$PRESET_DIR/lint-config/"*; do
  [[ -f "$f" ]] && install_file "$f" "$TARGET/$(basename "$f")"
done

# CI workflows -> .github/workflows ; non-workflow CI config (budgets etc.) -> project root
for f in "$PRESET_DIR/ci/"*; do
  [[ -f "$f" ]] || continue
  case "$(basename "$f")" in
    *.yml|*.yaml) install_file "$f" "$TARGET/.github/workflows/$(basename "$f")" ;;
    *)            install_file "$f" "$TARGET/$(basename "$f")" ;;
  esac
done

# git hooks -> .husky/ ; hook tool configs -> project root
for f in "$PRESET_DIR/hooks/"*; do
  [[ -f "$f" ]] || continue
  case "$(basename "$f")" in
    *.*) install_file "$f" "$TARGET/$(basename "$f")" ;;          # configs (have extensions)
    *)   install_file "$f" "$TARGET/.husky/$(basename "$f")" 755 ;; # hook scripts (no extension)
  esac
done

# dependabot -> .github/
install_file "$PRESET_DIR/dependabot.yml" "$TARGET/.github/dependabot.yml"

# env schema example -> env.schema.ts
install_file "$PRESET_DIR/env.schema.example" "$TARGET/env.schema.ts"

# --- 3. drop in templates ----------------------------------------------------
echo "[3/3] Working templates -> docs/"
install_file "$LIB_ROOT/01-context/adr.template.md"              "$TARGET/docs/adr.template.md"
install_file "$LIB_ROOT/01-context/glossary.template.md"         "$TARGET/docs/glossary.md"
install_file "$LIB_ROOT/01-context/architecture-map.template.md" "$TARGET/docs/architecture-map.md"
install_file "$LIB_ROOT/02-product/spec.template.md"             "$TARGET/docs/spec.template.md"
install_file "$LIB_ROOT/03-design/threat-model.template.md"      "$TARGET/docs/threat-model.template.md"
install_file "$LIB_ROOT/07-operations/incident-runbook.template.md" "$TARGET/docs/incident-runbook.template.md"

# --- summary ------------------------------------------------------------------
echo
echo "Done: $created created, $skipped skipped (already existed)."
echo "Next steps:"
echo "  1. Fill the <ANGLE_BRACKET> blanks in CLAUDE.md and docs/."
echo "  2. Initialize the project (git init, pnpm init / framework scaffold) if not done."
echo "  3. Wire hooks: pnpm add -D husky lint-staged @commitlint/cli @commitlint/config-conventional && pnpm exec husky init (hooks already in .husky/)."
echo "  4. Read $LIB_ROOT/00-governance/agent-operating-rules.md before letting an agent loose."
