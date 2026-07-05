#!/usr/bin/env bash
set -euo pipefail

CLEAN_REMOTE=false
if [[ "${1:-}" == "--clean" ]]; then
  CLEAN_REMOTE=true
  shift
fi

REPO_ID="${1:-${HF_PROMPT_GUIDES_REPO:-}}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GUIDES_DIR="$ROOT_DIR/prompt-guides"

if [[ -z "$REPO_ID" ]]; then
  cat >&2 <<'EOF'
Usage:
  script/publish_prompt_guides.sh MikoMurra/FuguFableFlow-Prompt-Guides
  script/publish_prompt_guides.sh --clean MikoMurra/FuguFableFlow-Prompt-Guides

Or set:
  export HF_PROMPT_GUIDES_REPO="MikoMurra/FuguFableFlow-Prompt-Guides"
  script/publish_prompt_guides.sh
EOF
  exit 2
fi

if ! command -v hf >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Missing Hugging Face CLI `hf`.

Install it:
  curl -LsSf https://hf.co/cli/install.sh | bash

Then log in:
  hf auth login
EOF
  exit 127
fi

if ! hf auth whoami >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Hugging Face CLI is not logged in for this shell.

Run:
  hf auth login

Use a token with write access to the target Dataset namespace.
EOF
  exit 1
fi

python3 "$ROOT_DIR/script/generate_prompt_guides_manifest.py" --root "$GUIDES_DIR"

DELETE_ARGS=()
if [[ "$CLEAN_REMOTE" == true ]]; then
  DELETE_ARGS=(
    --delete ".build/**"
    --delete ".codex/**"
    --delete ".swiftpm/**"
    --delete "Assets/**"
    --delete "Resources/**"
    --delete "Sources/**"
    --delete "Tests/**"
    --delete "dist/**"
    --delete "docs/**"
    --delete "marketing/**"
    --delete "script/**"
    --delete "prompt-guides/**"
    --delete "sources/**"
    --delete ".gitattributes"
    --delete ".gitignore"
    --delete "LICENSE"
    --delete "Package.swift"
    --delete "SECURITY.md"
  )
fi

if ! UPLOAD_OUTPUT="$(hf upload "$REPO_ID" "$GUIDES_DIR" . --repo-type=dataset --exclude "sources/**" "${DELETE_ARGS[@]}" 2>&1)"; then
  printf '%s\n' "$UPLOAD_OUTPUT" >&2
  if [[ "$UPLOAD_OUTPUT" == *"403 Forbidden"* || "$UPLOAD_OUTPUT" == *"don't have the rights"* ]]; then
    cat >&2 <<EOF

Publish failed because this token cannot create or write to:
  $REPO_ID

Fix options:
  1. Log in with the Hugging Face account that owns that namespace:
       hf auth login --force

  2. Use your actual HF username or an org where your token has write access:
       ./script/publish_prompt_guides.sh your-username/FuguFableFlow-Prompt-Guides

  3. Create the Dataset repo in the Hugging Face UI first, then rerun this script
     with a write-scoped token that has access to it.
EOF
  fi
  exit 1
fi
printf '%s\n' "$UPLOAD_OUTPUT"

if [[ "$CLEAN_REMOTE" == true ]]; then
  echo "Cleaned accidental repo files from dataset before publishing guide payload."
fi
echo "Published prompt guides to: https://huggingface.co/datasets/$REPO_ID"
