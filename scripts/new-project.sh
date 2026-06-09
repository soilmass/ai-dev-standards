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
#      dependabot.yml -> .github/, env.schema.example -> env.schema.ts,
#      project-config/** -> project root (RECURSIVE, relative paths preserved) with
#      the .example stripped: tool configs (vitest/playwright/drizzle), .gitignore,
#      the test scaffolding (tests/setup.ts, MSW server+handlers, example
#      unit/e2e/visual tests), instrumentation.ts (boot env-validation), and the
#      db/schema.ts starter — e.g. tests/msw/server.example.ts -> tests/msw/server.ts.
#   3. Drops the working templates into <target>/docs/ (incl. docs/slos.md and
#      docs/debt-log.md starters).
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

# per-project tool configs -> project root, '.example' stripped, RECURSIVELY so
# nested paths are preserved (e.g. project-config/tests/msw/server.example.ts ->
# <project>/tests/msw/server.ts). gitignore.example -> .gitignore is special-cased;
# foo.example.ts -> foo.ts; foo.example -> foo. install_file keeps it idempotent.
if [[ -d "$PRESET_DIR/project-config" ]]; then
  PC_ROOT="$PRESET_DIR/project-config"
  while IFS= read -r -d '' f; do
    rel="${f#"$PC_ROOT"/}"          # path relative to project-config/
    dir="$(dirname "$rel")"         # '.' for top-level files
    base="$(basename "$rel")"
    case "$base" in
      gitignore.example)     base=".gitignore" ;;
      gitattributes.example) base=".gitattributes" ;;
      env.example)           base=".env.example" ;;       # dotfile devs copy to .env.local
      *.example.*)           base="${base/.example./.}" ;; # collapse the '.example.' segment only
      *.example)             base="${base%.example}" ;;
    esac
    if [[ "$dir" == "." ]]; then
      install_file "$f" "$TARGET/$base"
    else
      install_file "$f" "$TARGET/$dir/$base"
    fi
  done < <(find "$PC_ROOT" -type f -print0)
fi

# --- 3. drop in templates ----------------------------------------------------
echo "[3/3] Working templates -> docs/"
install_file "$LIB_ROOT/01-context/adr.template.md"              "$TARGET/docs/adr.template.md"
install_file "$LIB_ROOT/01-context/glossary.template.md"         "$TARGET/docs/glossary.md"
install_file "$LIB_ROOT/01-context/architecture-map.template.md" "$TARGET/docs/architecture-map.md"
install_file "$LIB_ROOT/02-product/spec.template.md"             "$TARGET/docs/spec.template.md"
install_file "$LIB_ROOT/03-design/threat-model.template.md"      "$TARGET/docs/threat-model.template.md"
install_file "$LIB_ROOT/07-operations/incident-runbook.template.md" "$TARGET/docs/incident-runbook.template.md"
install_file "$LIB_ROOT/07-operations/slos.template.md"          "$TARGET/docs/slos.md"
install_file "$LIB_ROOT/08-maintenance/debt-log.template.md"     "$TARGET/docs/debt-log.md"

# helper scripts -> project scripts/ (executable)
install_file "$LIB_ROOT/01-context/setup-branch-protection.template.sh" "$TARGET/scripts/setup-branch-protection.sh" 755
install_file "$LIB_ROOT/01-context/configure-signing.template.sh"       "$TARGET/scripts/configure-signing.sh" 755

# GitHub community-health files -> .github/ (tool-agnostic; fill the <ANGLE_BRACKET> blanks)
install_file "$LIB_ROOT/01-context/CODEOWNERS.template"      "$TARGET/.github/CODEOWNERS"
install_file "$LIB_ROOT/01-context/SECURITY.template.md"     "$TARGET/.github/SECURITY.md"
install_file "$LIB_ROOT/01-context/CONTRIBUTING.template.md" "$TARGET/.github/CONTRIBUTING.md"
install_file "$LIB_ROOT/01-context/issue-templates/bug_report.template.md"      "$TARGET/.github/ISSUE_TEMPLATE/bug_report.md"
install_file "$LIB_ROOT/01-context/issue-templates/feature_request.template.md" "$TARGET/.github/ISSUE_TEMPLATE/feature_request.md"
install_file "$LIB_ROOT/01-context/issue-templates/config.template.yml"         "$TARGET/.github/ISSUE_TEMPLATE/config.yml"

# --- summary ------------------------------------------------------------------
echo
echo "Done: $created created, $skipped skipped (already existed)."
echo "Next steps (full walkthrough: the 'Project setup after bootstrap' section of CLAUDE.md):"
echo "  1. Scaffold the framework app if not done, then fill the <ANGLE_BRACKET> blanks in CLAUDE.md and docs/."
echo "  2. Install the stack's dependencies — the canonical pnpm add lines are in CLAUDE.md's setup section."
echo "  3. Install the gitleaks binary (brew install gitleaks | github.com/gitleaks/gitleaks/releases) — the pre-commit hook fails closed without it."
echo "  4. Wire hooks: pnpm exec husky init (scripts already in .husky/), then make one test commit on a branch."
echo "  4b. Turn on verified signing: bash scripts/configure-signing.sh (then commits/tags are signed)."
echo "      Fill the <ANGLE_BRACKET> blanks in .github/CODEOWNERS, SECURITY.md, and ISSUE_TEMPLATE/config.yml."
echo "  5. After the first push: run 'bash scripts/setup-branch-protection.sh' (needs gh, authenticated) to apply the required-checks ruleset — or follow the manual checklist in 05-verification/ci-pipeline.md."
echo "  6. Read $LIB_ROOT/00-governance/agent-operating-rules.md before letting an agent loose."
