#!/usr/bin/env bash
# Agent / kullanıcı için özet: sürüm, APK linki, son derleme, son özellikler.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "=== Canlifal APK durumu ==="
echo "Sürüm (kaynak): ${VERSION}"
echo "İndirme: ${APK_URL}"
echo ""

if [[ -f "${ROOT}/docs/LATEST_APK_BUILD.md" ]]; then
  echo "--- Son başarılı derleme (CI) ---"
  head -40 "${ROOT}/docs/LATEST_APK_BUILD.md"
  echo ""
fi

echo "--- Son özellikler (CHANGELOG) ---"
"${ROOT}/scripts/extract-changelog-head.sh" 2>/dev/null || true
echo ""

RUN_JSON=$(gh run list --repo "$REPO" --workflow=build-apk.yml --branch=main --limit=1 --json status,conclusion,url,displayTitle,createdAt 2>/dev/null || echo '[]')
echo "--- GitHub Actions (son main derlemesi) ---"
echo "$RUN_JSON" | python3 -c "
import sys, json
d = json.load(sys.stdin)
if not d:
    print('Kayıt yok')
else:
    r = d[0]
    print(f\"Başlık: {r.get('displayTitle','')}\")
    print(f\"Durum: {r.get('status')} / {r.get('conclusion')}\")
    print(f\"Zaman: {r.get('createdAt')}\")
    print(f\"URL: {r.get('url')}\")
" 2>/dev/null || echo "gh run list okunamadı"
