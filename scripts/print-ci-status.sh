#!/usr/bin/env bash
# Kısa CI özeti — agent her kullanıcı yanıtında çalıştırır (tam rapor: print-build-status.sh).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
WORKFLOW_URL="https://github.com/${REPO}/actions/workflows/build-apk.yml"
APK_URL="https://github.com/${REPO}/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

RELEASE_NAME=""
RELEASE_TAG=""
if command -v gh >/dev/null 2>&1; then
  RELEASE_NAME=$(gh release view apk-latest --repo "$REPO" --json name -q .name 2>/dev/null || true)
  RELEASE_TAG=$(gh release view apk-latest --repo "$REPO" --json tagName -q .tagName 2>/dev/null || true)
fi

STATUS="unknown"
CONCLUSION=""
RUN_URL=""
CREATED=""
if command -v gh >/dev/null 2>&1; then
  RUN_JSON=$(gh run list --repo "$REPO" --workflow=build-apk.yml --branch=main --limit=1 \
    --json status,conclusion,url,createdAt 2>/dev/null || echo '[]')
  read -r STATUS CONCLUSION RUN_URL CREATED <<<"$(echo "$RUN_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if not d:
    print('unknown unknown  ')
else:
    r = d[0]
    print(r.get('status',''), r.get('conclusion') or '-', r.get('url',''), r.get('createdAt',''))
" 2>/dev/null || echo 'unknown unknown  ')"
fi

LATEST_DOC=""
if [[ -f "${ROOT}/docs/LATEST_APK_BUILD.md" ]]; then
  LATEST_DOC=$(grep -E '^\| Sürüm \|' "${ROOT}/docs/LATEST_APK_BUILD.md" 2>/dev/null | head -1 | sed 's/|//g' | awk -F'Sürüm' '{print $2}' | xargs || true)
fi

echo "=== CI (kısa) ==="
echo "Kaynak sürüm (pubspec): ${VERSION}"
echo "apk-latest release: ${RELEASE_NAME:-—}"
echo "Son başarılı CI (LATEST_APK_BUILD): ${LATEST_DOC:-—}"
echo "Son workflow run: status=${STATUS} conclusion=${CONCLUSION}"
echo "Run URL: ${RUN_URL:-—}"
echo "Workflow: ${WORKFLOW_URL}"
echo "APK indir: ${APK_URL}"
echo "Tam rapor: bash scripts/print-build-status.sh"
