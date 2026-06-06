#!/bin/bash
set -euo pipefail
REPO="mesutbyrm/Cursor-Flutter-"
{
  gh workflow run "Build release APK" --repo "$REPO" --ref cursor/auth-social-ux-7009
  sleep 5
  gh run list --repo "$REPO" --workflow "Build release APK" -L 2
} > /workspace/workflow-trigger.txt 2>&1
