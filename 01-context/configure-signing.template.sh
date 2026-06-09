#!/usr/bin/env bash
# configure-signing.sh — turn on verified commit & tag signing for this repo.
#
# Implements 04-build/commit-signing.md. SSH signing by default (simplest, modern);
# pass --gpg for OpenPGP. Sets LOCAL (per-repo) git config so it can't disturb your
# other repositories; pass --global to apply machine-wide. Registers the public key
# on GitHub (as a *signing* key, separate from auth keys) via gh when available.
#
# Requires: git, and ssh-keygen (SSH mode) or gpg (GPG mode); gh optional (for key
# upload). Idempotent — re-running re-asserts the same config. DRY_RUN=1 prints the
# commands without running them.
#
# Usage: bash scripts/configure-signing.sh [--ssh|--gpg] [--local|--global]

set -euo pipefail

METHOD=ssh
SCOPE=--local
DRY_RUN="${DRY_RUN:-0}"
for arg in "$@"; do
  case "$arg" in
    --ssh)    METHOD=ssh ;;
    --gpg)    METHOD=gpg ;;
    --local)  SCOPE=--local ;;
    --global) SCOPE=--global ;;
    *) echo "Usage: $0 [--ssh|--gpg] [--local|--global]" >&2; exit 1 ;;
  esac
done

run() { echo "  + $*"; [[ "$DRY_RUN" == "1" ]] || "$@"; }

command -v git >/dev/null 2>&1 || { echo "ERROR: git not found." >&2; exit 1; }

echo "Configuring $METHOD commit/tag signing ($SCOPE)…"

if [[ "$METHOD" == "ssh" ]]; then
  command -v ssh-keygen >/dev/null 2>&1 || { echo "ERROR: ssh-keygen not found." >&2; exit 1; }
  KEY=""
  for cand in "$HOME/.ssh/id_ed25519.pub" "$HOME/.ssh/id_ecdsa.pub" "$HOME/.ssh/id_rsa.pub"; do
    [[ -f "$cand" ]] && { KEY="$cand"; break; }
  done
  if [[ -z "$KEY" ]]; then
    echo "No SSH public key in ~/.ssh. Create one, then re-run:" >&2
    echo "  ssh-keygen -t ed25519 -C \"\$(git config user.email)\"" >&2
    exit 1
  fi
  echo "Using SSH signing key: $KEY"
  run git config "$SCOPE" gpg.format ssh
  run git config "$SCOPE" user.signingkey "$KEY"
  run git config "$SCOPE" commit.gpgsign true
  run git config "$SCOPE" tag.gpgsign true

  # allowed_signers lets `git log --show-signature` verify your own signatures locally.
  SIGNERS="$HOME/.config/git/allowed_signers"
  EMAIL="$(git config user.email || true)"
  run git config "$SCOPE" gpg.ssh.allowedSignersFile "$SIGNERS"
  if [[ -n "$EMAIL" ]] && ! { [[ -f "$SIGNERS" ]] && grep -qF "$(cat "$KEY")" "$SIGNERS" 2>/dev/null; }; then
    echo "  + append '$EMAIL <key>' to $SIGNERS"
    if [[ "$DRY_RUN" != "1" ]]; then
      mkdir -p "$(dirname "$SIGNERS")"
      printf '%s %s\n' "$EMAIL" "$(cat "$KEY")" >> "$SIGNERS"
    fi
  fi

  if command -v gh >/dev/null 2>&1; then
    run gh ssh-key add "$KEY" --type signing --title "git signing ($(hostname 2>/dev/null || echo local))" \
      || echo "  (gh ssh-key add failed — add $KEY in GitHub → Settings → SSH and GPG keys → New SSH key, type 'Signing Key')"
  else
    echo "  gh not found — add $KEY in GitHub as a Signing Key manually."
  fi

else  # GPG
  command -v gpg >/dev/null 2>&1 || { echo "ERROR: gpg not found." >&2; exit 1; }
  KEYID="$(gpg --list-secret-keys --keyid-format=long 2>/dev/null | awk '/^sec/{print $2}' | cut -d/ -f2 | head -1 || true)"
  if [[ -z "$KEYID" ]]; then
    echo "No GPG secret key found. Create one, then re-run:" >&2
    echo "  gpg --full-generate-key   # choose ed25519 or RSA 4096" >&2
    exit 1
  fi
  echo "Using GPG key: $KEYID"
  run git config "$SCOPE" gpg.format openpgp
  run git config "$SCOPE" user.signingkey "$KEYID"
  run git config "$SCOPE" commit.gpgsign true
  run git config "$SCOPE" tag.gpgsign true

  if command -v gh >/dev/null 2>&1; then
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "  + gpg --armor --export $KEYID | gh gpg-key add -"
    else
      gpg --armor --export "$KEYID" | gh gpg-key add - \
        || echo "  (gh gpg-key add failed — export with 'gpg --armor --export $KEYID' and add it in GitHub settings)"
    fi
  else
    echo "  gh not found — run 'gpg --armor --export $KEYID' and add the key in GitHub settings."
  fi
fi

echo
echo "Done. Verify with a signed test commit:"
echo "  git commit --allow-empty -m 'chore: verify signing' && git log --show-signature -1"
echo "GitHub shows 'Verified' once the key is registered. Enforce it repo-side with"
echo "scripts/setup-branch-protection.sh (it enables 'require signed commits' + signed tags)."
