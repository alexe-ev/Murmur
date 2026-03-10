#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <branch> <title> [body-file]" >&2
  echo "If [body-file] is omitted, PR body is read from stdin." >&2
  exit 1
fi

branch="$1"
title="$2"
body_file="${3:-}"

cleanup() {
  if [[ -n "${tmp_body_file:-}" && -f "$tmp_body_file" ]]; then
    rm -f "$tmp_body_file"
  fi
}
trap cleanup EXIT

if [[ -z "$body_file" ]]; then
  tmp_body_file="$(mktemp)"
  cat > "$tmp_body_file"
  body_file="$tmp_body_file"
fi

gh pr create \
  --base main \
  --head "$branch" \
  --title "$title" \
  --body-file "$body_file"
