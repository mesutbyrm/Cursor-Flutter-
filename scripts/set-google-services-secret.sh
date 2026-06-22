#!/usr/bin/env bash
# GOOGLE_SERVICES_JSON_BASE64 GitHub secret güncelleme (repo admin gh oturumu gerekir).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON="$ROOT/mobile/android/app/google-services.json"
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"

if [[ ! -f "$JSON" ]]; then
  echo "Hata: $JSON bulunamadı"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "Hata: gh CLI gerekli"
  exit 1
fi

echo "Secret güncelleniyor: GOOGLE_SERVICES_JSON_BASE64"
echo "Kaynak: $JSON"
echo "SHA-1: $(jq -r '.client[0].oauth_client[]? | select(.client_type==1) | .android_info.certificate_hash' "$JSON" | head -1)"
echo ""

base64 -w0 "$JSON" | gh secret set GOOGLE_SERVICES_JSON_BASE64 --repo "$REPO"

echo "✓ Secret güncellendi. CI APK derlemesi için:"
echo "  gh workflow run build-apk.yml --repo $REPO"
