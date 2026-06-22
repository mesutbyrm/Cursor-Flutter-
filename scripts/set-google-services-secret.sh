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

if ! command -v jq >/dev/null 2>&1; then
  echo "Hata: jq gerekli (SHA-1 doğrulaması için)"
  exit 1
fi

SHA1="$(jq -r '.client[0].oauth_client[]? | select(.client_type==1) | .android_info.certificate_hash' "$JSON" | head -1)"
PKG="$(jq -r '.client[0].client_info.android_client_info.package_name' "$JSON")"

echo "Secret güncelleniyor: GOOGLE_SERVICES_JSON_BASE64"
echo "Repo:   $REPO"
echo "Kaynak: $JSON"
echo "Paket:  $PKG"
echo "SHA-1:  $SHA1"
echo ""

if ! gh auth status >/dev/null 2>&1; then
  echo "Hata: gh oturumu yok. Önce: gh auth login"
  exit 1
fi

if ! gh api "repos/$REPO/actions/secrets/public-key" --silent >/dev/null 2>&1; then
  echo "Hata: GitHub secret yazma izni yok (HTTP 403)."
  echo "Bu komutu repo admin hesabıyla yerel makinede çalıştırın:"
  echo "  bash scripts/set-google-services-secret.sh"
  echo ""
  echo "Alternatif (GitHub UI): Settings → Secrets and variables → Actions"
  echo "  Name: GOOGLE_SERVICES_JSON_BASE64"
  echo "  Value: base64 -w0 mobile/android/app/google-services.json"
  exit 1
fi

base64 -w0 "$JSON" | gh secret set GOOGLE_SERVICES_JSON_BASE64 --repo "$REPO"

echo ""
echo "Doğrulama (yerel decode):"
if base64 -d <<<"$(base64 -w0 "$JSON")" | jq -e '.project_info.project_id' >/dev/null 2>&1; then
  echo "  ✓ base64 encode/decode OK"
else
  echo "  ! base64 doğrulaması başarısız"
fi
echo ""
echo "Not: GitHub UI'ye yalnızca base64 yapıştırın (ham JSON değil)."
echo "     Ham JSON yapıştırıldıysa CI yine de kabul eder (build-apk.yml)."
