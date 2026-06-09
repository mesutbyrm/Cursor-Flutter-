#!/bin/bash
set -euo pipefail
cd /workspace
{
  echo "=== BRANCH ==="
  git branch --show-current
  echo "=== LOG ==="
  git log --oneline -8
  echo "=== MAIN vs HEAD pubspec ==="
  git show main:mobile/pubspec.yaml 2>/dev/null | head -6 || echo "no main"
  head -6 mobile/pubspec.yaml
  echo "=== REMOTE BRANCHES (cursor) ==="
  git branch -r | grep cursor | tail -15
} > "${TMPDIR:-/tmp}/canlifal-review-state.txt" 2>&1
