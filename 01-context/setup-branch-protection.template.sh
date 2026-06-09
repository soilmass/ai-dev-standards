#!/usr/bin/env bash
# setup-branch-protection.sh — apply this project's branch + tag protection.
#
# Bootstrap injects everything EXCEPT host-side repo settings; protection is the
# documented "one manual step" (05-verification/ci-pipeline.md). This script
# automates it via the GitHub API so the step is reproducible instead of a
# click-path you redo from memory.
#
# What it sets:
#   On the default branch (mirroring ci-pipeline.md's checklist):
#     - Require a pull request before merging (no direct pushes; 0 approvals — solo).
#     - Require every PR job as a status check, branches up to date before merge.
#     - Enforce on admins too (no self-bypass — you are the admin and so is every agent run).
#     - Block force pushes and deletions.
#     - Require SIGNED commits (04-build/commit-signing.md).
#   On version tags (06-delivery/release-process.md):
#     - A repository ruleset 'protect-version-tags' over refs/tags/v* that blocks
#       deletion + non-fast-forward (no clobbering a released tag) and requires
#       signed tags.
#
# The required-check list is DERIVED from .github/workflows/pr.yml's job names, so
# it can never drift from the actual pipeline: add a PR job and it becomes required
# the next time you run this.
#
# Requires: gh (authenticated — `gh auth status`). Run from the repo root after the
# first push. Idempotent (branch = full PUT; signatures = POST no-op once on; tag
# ruleset = created only if absent). Set DRY_RUN=1 to print every request body and
# exit without changing anything.

set -euo pipefail

DRY_RUN="${DRY_RUN:-0}"
WORKFLOW=".github/workflows/pr.yml"
RULESET_NAME="protect-version-tags"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI 'gh' not found. Install it and run 'gh auth login' first." >&2
  exit 1
fi
if [[ ! -f "$WORKFLOW" ]]; then
  echo "ERROR: $WORKFLOW not found — run this from the repo root of a bootstrapped project." >&2
  exit 1
fi

# Job names are the check-run contexts. With standard 2-space YAML a job-level
# 'name:' sits at 4-space indent; the top-level workflow name is at column 0,
# step names are dash-prefixed ('      - name:'), and a step's 'with: name:' is
# deeper — so a 4-space, no-dash match selects job names only.
# (read loop, not mapfile — portable to bash 3.2, e.g. macOS system bash.)
trim() { local s="$1"; s="${s#"${s%%[![:space:]]*}"}"; s="${s%"${s##*[![:space:]]}"}"; printf '%s' "$s"; }
checks=()
while IFS= read -r raw; do
  name="$(trim "$raw")"
  # Strip one layer of surrounding YAML quotes so the context matches the
  # check-run name GitHub actually reports (a quoted 'name: "Build: x"' would
  # otherwise become a literal-quoted context that no check ever satisfies,
  # silently blocking every merge).
  if [[ "$name" == \"*\" ]]; then name="${name#\"}"; name="${name%\"}"; fi
  if [[ "$name" == \'*\' ]]; then name="${name#\'}"; name="${name%\'}"; fi
  [[ -n "$name" ]] && checks+=("$name")
done < <(grep -E '^    name:[[:space:]]' "$WORKFLOW" | sed -E 's/^    name:[[:space:]]+//')
if [[ ${#checks[@]} -eq 0 ]]; then
  echo "ERROR: found no job names at 4-space indent in $WORKFLOW (expects standard 2-space YAML)." >&2
  echo "       Check the indentation, or set the required checks manually per ci-pipeline.md." >&2
  exit 1
fi

# Build the contexts JSON array without jq/python (portable).
contexts_json=""
for c in "${checks[@]}"; do
  esc="${c//\\/\\\\}"
  esc="${esc//\"/\\\"}"
  contexts_json+="\"${esc}\","
done
contexts_json="[${contexts_json%,}]"

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name 2>/dev/null || true)"
BRANCH="${BRANCH:-main}"

branch_body="$(cat <<JSON
{
  "required_status_checks": { "strict": true, "contexts": ${contexts_json} },
  "enforce_admins": true,
  "required_pull_request_reviews": { "required_approving_review_count": 0 },
  "restrictions": null,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
)"

tag_ruleset_body="$(cat <<JSON
{
  "name": "${RULESET_NAME}",
  "target": "tag",
  "enforcement": "active",
  "conditions": { "ref_name": { "include": ["refs/tags/v*"], "exclude": [] } },
  "rules": [ { "type": "deletion" }, { "type": "non_fast_forward" }, { "type": "required_signatures" } ]
}
JSON
)"

echo "Repo:   $REPO"
echo "Branch: $BRANCH"
echo "Required checks (${#checks[@]}):"
printf '  - %s\n' "${checks[@]}"

if [[ "$DRY_RUN" == "1" ]]; then
  echo
  echo "DRY_RUN=1 — no changes sent. Planned requests:"
  echo
  echo "PUT repos/${REPO}/branches/${BRANCH}/protection"
  echo "$branch_body"
  echo
  echo "POST repos/${REPO}/branches/${BRANCH}/protection/required_signatures  (require signed commits)"
  echo
  echo "POST repos/${REPO}/rulesets  (tag protection, only if '${RULESET_NAME}' absent)"
  echo "$tag_ruleset_body"
  exit 0
fi

# 1. Branch protection.
echo "$branch_body" | gh api -X PUT "repos/${REPO}/branches/${BRANCH}/protection" \
  -H "Accept: application/vnd.github+json" --input - >/dev/null
echo "Branch protection applied to ${REPO}@${BRANCH}."

# 2. Require signed commits (POST enables; no-op if already enabled).
gh api -X POST "repos/${REPO}/branches/${BRANCH}/protection/required_signatures" \
  -H "Accept: application/vnd.github+json" >/dev/null
echo "Required signed commits enabled on ${BRANCH}."

# 3. Tag-protection ruleset — create only if absent (idempotent; POST would dup).
existing="$(gh api "repos/${REPO}/rulesets" --jq '.[].name' 2>/dev/null || true)"
if printf '%s\n' "$existing" | grep -qx "$RULESET_NAME"; then
  echo "Tag ruleset '${RULESET_NAME}' already exists — leaving as is."
else
  echo "$tag_ruleset_body" | gh api -X POST "repos/${REPO}/rulesets" \
    -H "Accept: application/vnd.github+json" --input - >/dev/null
  echo "Created tag-protection ruleset '${RULESET_NAME}' over refs/tags/v*."
fi
