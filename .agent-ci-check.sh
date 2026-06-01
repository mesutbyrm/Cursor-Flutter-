#!/bin/bash
REPO="mesutbyrm/Cursor-Flutter-"
{
  echo "=== main branch runs ==="
  /usr/local/bin/gh run list --repo "$REPO" -b main -L 8
  echo "=== failed runs ==="
  /usr/local/bin/gh run list --repo "$REPO" -b main --status failure -L 5
} > /workspace/ci-check.txt 2>&1
