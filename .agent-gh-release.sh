#!/bin/bash
set -euo pipefail
REPO="mesutbyrm/Cursor-Flutter-"
OUT="/workspace/apk-check.txt"
{
  echo "=== release view ==="
  gh release view apk-latest --repo "$REPO" 2>&1 || true
  echo "=== latest runs ==="
  gh run list --repo "$REPO" --workflow "Build release APK" -L 3 2>&1 || true
} > "$OUT" 2>&1
