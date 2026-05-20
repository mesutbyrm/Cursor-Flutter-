#!/usr/bin/env bash
# main dalındaki son Build release APK iş akışının bitmesini bekler.
set -euo pipefail
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
TIMEOUT_SEC="${1:-900}"
POLL_SEC="${2:-20}"
START=$(date +%s)

echo "APK derlemesi bekleniyor (repo: $REPO, zaman aşımı: ${TIMEOUT_SEC}s)..."

while true; do
  NOW=$(date +%s)
  if (( NOW - START > TIMEOUT_SEC )); then
    echo "TIMEOUT"
    exit 2
  fi

  JSON=$(gh run list --repo "$REPO" --workflow=build-apk.yml --branch=main --limit=1 --json databaseId,status,conclusion,headSha,displayTitle,url,createdAt 2>/dev/null || echo '[]')
  STATUS=$(echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['status'] if d else 'none')" 2>/dev/null || echo "none")
  CONCLUSION=$(echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0].get('conclusion') or '') if d else ''" 2>/dev/null || echo "")
  RUN_ID=$(echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['databaseId'] if d else '')" 2>/dev/null || echo "")
  URL=$(echo "$JSON" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['url'] if d else '')" 2>/dev/null || echo "")

  if [[ "$STATUS" == "completed" ]]; then
    echo "RUN_ID=$RUN_ID"
    echo "CONCLUSION=$CONCLUSION"
    echo "URL=$URL"
    if [[ "$CONCLUSION" == "success" ]]; then
      echo "SUCCESS"
      exit 0
    fi
    echo "FAILED"
    exit 1
  fi

  echo "Durum: $STATUS (${RUN_ID:-?}) — ${POLL_SEC}s sonra tekrar..."
  sleep "$POLL_SEC"
done
