#!/usr/bin/env bash
# Google Sign-In yapılandırmasını doğrular: google-services.json, SHA-1, Web client ID.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON="$ROOT/mobile/android/app/google-services.json"
ANDROID_DIR="$ROOT/mobile/android"

echo "=== Google Sign-In yapılandırma kontrolü ==="
echo

if [[ ! -f "$JSON" ]]; then
  echo "❌ google-services.json yok: $JSON"
  echo "   Firebase Console → Android uygulaması → İndir → bu yola kopyalayın."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "❌ jq gerekli (apt install jq)"
  exit 1
fi

PROJECT_NUMBER=$(jq -r '.project_info.project_number' "$JSON")
PROJECT_ID=$(jq -r '.project_info.project_id' "$JSON")
PACKAGE=$(jq -r '.client[0].client_info.android_client_info.package_name' "$JSON")
WEB_CLIENT=$(jq -r '.client[0].oauth_client[]? | select(.client_type == 3) | .client_id' "$JSON" | head -1)
ANDROID_CLIENT=$(jq -r '.client[0].oauth_client[]? | select(.client_type == 1) | .client_id' "$JSON" | head -1)
REGISTERED_SHA=$(jq -r '.client[0].oauth_client[]? | select(.client_type == 1) | .android_info.certificate_hash // empty' "$JSON" | head -1)

echo "✓ google-services.json bulundu"
echo "  project_number : $PROJECT_NUMBER"
echo "  project_id     : $PROJECT_ID"
echo "  package        : $PACKAGE"
echo "  Web client ID  : ${WEB_CLIENT:-<yok — client_type:3 gerekli>}"
echo "  Android client : ${ANDROID_CLIENT:-<yok>}"
if [[ -n "$REGISTERED_SHA" ]]; then
  echo "  JSON SHA-1     : ${REGISTERED_SHA:0:2}:${REGISTERED_SHA:2:2}:… (colonless: $REGISTERED_SHA)"
fi
echo

if [[ "$PROJECT_NUMBER" != "24667749197" ]]; then
  echo "⚠ project_number beklenen 24667749197 değil: $PROJECT_NUMBER"
fi
if [[ "$PACKAGE" != "com.mesutbyrm.canlifal" ]]; then
  echo "⚠ package_name beklenen com.mesutbyrm.canlifal değil: $PACKAGE"
fi
if [[ -z "$WEB_CLIENT" || "$WEB_CLIENT" == "null" ]]; then
  echo "❌ Web OAuth client (client_type: 3) google-services.json içinde yok."
  echo "   Firebase → Authentication → Google → Web SDK configuration"
  exit 1
fi

echo "=== Gradle signingReport (bu makine) ==="
cd "$ANDROID_DIR"
REPORT=$("./gradlew" signingReport 2>/dev/null || true)
DEBUG_SHA=$(echo "$REPORT" | awk '/Variant: debug$/{f=1} f&&/SHA1:/{print $2; exit}')
RELEASE_SHA=$(echo "$REPORT" | awk '/Variant: release$/{f=1} f&&/SHA1:/{print $2; exit}')

echo "  Debug SHA-1   : ${DEBUG_SHA:-<alınamadı>}"
echo "  Release SHA-1 : ${RELEASE_SHA:-<alınamadı>}"
echo

sha_colonless() {
  echo "$1" | tr -d ':'
}

if [[ -n "$REGISTERED_SHA" && -n "$DEBUG_SHA" ]]; then
  LOCAL_DEBUG=$(sha_colonless "$DEBUG_SHA" | tr '[:upper:]' '[:lower:]')
  REGISTERED_LOWER=$(echo "$REGISTERED_SHA" | tr '[:upper:]' '[:lower:]')
  if [[ "$LOCAL_DEBUG" != "$REGISTERED_LOWER" ]]; then
    echo "❌ Debug SHA-1 Firebase google-services.json ile eşleşmiyor!"
    echo "   Yerel : $DEBUG_SHA"
    echo "   JSON  : $(echo "$REGISTERED_SHA" | sed 's/\(..\)/\1:/g;s/:$//')"
    echo "   → Firebase Console → Android app → SHA certificate fingerprints → Debug SHA-1 ekleyin"
    echo "   → google-services.json yeniden indirin"
    exit 1
  fi
  echo "✓ Debug SHA-1 google-services.json certificate_hash ile eşleşiyor"
fi

echo
echo "=== Dart sabitleri ==="
if [[ -f "$ROOT/mobile/lib/core/firebase/firebase_options_generated.dart" ]]; then
  GEN_WEB=$(grep "googleWebClientId" "$ROOT/mobile/lib/core/firebase/firebase_options_generated.dart" | sed -n "s/.*= '\([^']*\)'.*/\1/p")
  if [[ -n "$GEN_WEB" && "$GEN_WEB" != "$WEB_CLIENT" ]]; then
    echo "⚠ firebase_options_generated.dart Web client ID güncel değil."
    echo "   bash scripts/generate-firebase-options.sh çalıştırın"
  else
    echo "✓ firebase_options_generated.dart Web client ID uyumlu"
  fi
else
  echo "⚠ firebase_options_generated.dart yok — bash scripts/generate-firebase-options.sh"
fi

echo
echo "=== Özet ==="
echo "APK derlerken: flutter build apk --release \$(bash scripts/print-firebase-dart-defines.sh)"
echo "CI için secret: GOOGLE_SERVICES_JSON_BASE64"
echo "✓ Temel kontroller tamam"
