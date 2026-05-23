#!/usr/bin/env bash
# canlifal.com resmi yapılandırma dosyalarını indirir.
# Not: Site kökünde bu dosyalar Next.js [customSlug] ile HTML dönebilir;
#       o zaman dosyaları Firebase Console'dan indirip elle kopyalayın
#       veya canlifal.com `public/` altına statik yayınlayın.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_URL="${CANLIFAL_CONFIG_BASE_URL:-https://canlifal.com}"

MOBILE_GS="$ROOT/mobile/android/app/google-services.json"
API_ADMIN="$ROOT/api/canlifal-firebase-adminsdk.json"
API_DOCS="$ROOT/docs/canlifal-flutter-api-docs.txt"

is_json() {
  local f="$1"
  [[ -f "$f" ]] && head -c 1 "$f" | grep -q '{'
}

is_html() {
  local f="$1"
  [[ -f "$f" ]] && head -c 20 "$f" | grep -qi '<!DOCTYPE\|<html'
}

fetch_one() {
  local url="$1"
  local dest="$2"
  local label="$3"
  echo "→ $label"
  echo "  $url"
  if ! curl -fsSL --max-time 90 -o "$dest" "$url"; then
    echo "  ✗ indirilemedi"
    return 1
  fi
  if is_html "$dest"; then
    echo "  ✗ HTML döndü (statik dosya değil — site yönlendirmesini düzeltin)"
    rm -f "$dest"
    return 1
  fi
  echo "  ✓ $(wc -c <"$dest" | tr -d ' ') bayt → $dest"
  return 0
}

mkdir -p "$(dirname "$MOBILE_GS")" "$(dirname "$API_ADMIN")" "$(dirname "$API_DOCS")"

ok=0
fail=0

if fetch_one "$BASE_URL/google-services.json" "$MOBILE_GS" "Flutter Android (google-services.json)"; then
  ok=$((ok + 1))
  if command -v jq >/dev/null 2>&1; then
    bash "$ROOT/scripts/generate-firebase-options.sh" || true
  fi
else
  fail=$((fail + 1))
fi

if fetch_one "$BASE_URL/canlifal-firebase-adminsdk.json" "$API_ADMIN" "Firebase Admin SDK (sunucu)"; then
  ok=$((ok + 1))
else
  fail=$((fail + 1))
fi

if fetch_one "$BASE_URL/canlifal-flutter-api-docs.txt" "$API_DOCS" "Flutter API dokümantasyonu"; then
  ok=$((ok + 1))
else
  fail=$((fail + 1))
fi

echo ""
echo "Özet: $ok başarılı, $fail başarısız"
if [[ "$fail" -gt 0 ]]; then
  echo ""
  echo "Elle kurulum:"
  echo "  1. google-services.json → mobile/android/app/"
  echo "  2. canlifal-firebase-adminsdk.json → api/ + api/.env içinde:"
  echo "     GOOGLE_APPLICATION_CREDENTIALS=./canlifal-firebase-adminsdk.json"
  echo "  3. canlifal-flutter-api-docs.txt → docs/"
  echo ""
  echo "Site tarafı: dosyaları Next.js public/ köküne koyun (ör. public/google-services.json)."
  exit 1
fi

echo "Tamam. APK için: cd mobile && flutter build apk --release \$(bash ../scripts/print-firebase-dart-defines.sh)"
