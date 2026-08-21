#!/usr/bin/env bash
# CI: release keystore SHA-1 ↔ google-services.json eşleşmesini doğrular.
# Uyuşmazlık Google Sign-In ApiException 10 (DEVELOPER_ERROR) üretir.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
JSON="$ROOT/mobile/android/app/google-services.json"
KEYSTORE="$ROOT/mobile/android/app/release.keystore"
KEY_PROPS="$ROOT/mobile/android/key.properties"
REPO_JSON="$ROOT/mobile/android/app/google-services.repo.json"

sha_colonless() {
  echo "$1" | tr -d ': ' | tr '[:upper:]' '[:lower:]'
}

echo "=== CI Google Sign-In SHA-1 doğrulama ==="

if [[ ! -f "$JSON" ]]; then
  echo "::error::google-services.json yok — GOOGLE_SERVICES_JSON_BASE64 secret gerekli."
  exit 1
fi

if [[ ! -f "$KEYSTORE" ]]; then
  echo "::error::release.keystore yok — ANDROID_KEYSTORE_BASE64 secret gerekli."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "::error::jq gerekli"
  exit 1
fi

STORE_PASS="${ANDROID_KEYSTORE_PASSWORD:-}"
KEY_ALIAS="${ANDROID_KEY_ALIAS:-}"
KEY_PASS="${ANDROID_KEY_PASSWORD:-}"

if [[ -f "$KEY_PROPS" ]]; then
  [[ -z "$STORE_PASS" ]] && STORE_PASS="$(grep -E '^storePassword=' "$KEY_PROPS" | cut -d= -f2- || true)"
  [[ -z "$KEY_ALIAS" ]] && KEY_ALIAS="$(grep -E '^keyAlias=' "$KEY_PROPS" | cut -d= -f2- || true)"
  [[ -z "$KEY_PASS" ]] && KEY_PASS="$(grep -E '^keyPassword=' "$KEY_PROPS" | cut -d= -f2- || true)"
fi

if [[ -z "$STORE_PASS" || -z "$KEY_ALIAS" ]]; then
  echo "::error::Keystore şifresi/alias eksik (ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS)."
  exit 1
fi

RELEASE_SHA=$(
  keytool -list -v \
    -keystore "$KEYSTORE" \
    -alias "$KEY_ALIAS" \
    -storepass "$STORE_PASS" \
    -keypass "${KEY_PASS:-$STORE_PASS}" 2>/dev/null \
    | awk '/SHA1:/{print $2; exit}'
)

if [[ -z "$RELEASE_SHA" ]]; then
  echo "::error::Release keystore SHA-1 alınamadı (alias=$KEY_ALIAS)."
  exit 1
fi

echo "Release keystore SHA-1 : $RELEASE_SHA"

json_sha_matches() {
  local file="$1"
  local target
  target="$(sha_colonless "$RELEASE_SHA")"
  while IFS= read -r hash; do
    [[ -z "$hash" || "$hash" == "null" ]] && continue
    if [[ "$(sha_colonless "$hash")" == "$target" ]]; then
      return 0
    fi
  done < <(jq -r '.client[0].oauth_client[]? | select(.client_type == 1) | .android_info.certificate_hash // empty' "$file")
  return 1
}

WEB_CLIENT=$(jq -r '.client[0].oauth_client[]? | select(.client_type == 3) | .client_id' "$JSON" | head -1)
if [[ -z "$WEB_CLIENT" || "$WEB_CLIENT" == "null" ]]; then
  echo "::error::google-services.json içinde Web OAuth client (client_type: 3) yok."
  exit 1
fi

if json_sha_matches "$JSON"; then
  echo "✓ google-services.json release SHA-1 ile eşleşiyor"
  echo "  Web client ID: $WEB_CLIENT"
  exit 0
fi

REGISTERED=$(jq -r '.client[0].oauth_client[]? | select(.client_type == 1) | .android_info.certificate_hash // empty' "$JSON" | head -1)
echo "::warning::Secret google-services.json SHA-1 uyuşmuyor."
echo "  Keystore : $RELEASE_SHA"
echo "  JSON     : ${REGISTERED:-<yok>}"

if [[ -f "$REPO_JSON" ]] && json_sha_matches "$REPO_JSON"; then
  cp "$REPO_JSON" "$JSON"
  bash "$ROOT/scripts/generate-firebase-options.sh"
  echo "✓ Repo google-services.json kullanıldı (SHA-1 eşleşti)."
  exit 0
fi

echo "::error::Google Sign-In SHA-1 uyuşmazlığı — APK ApiException 10 verir."
echo "Firebase Console → Android app → SHA certificate fingerprints"
echo "Release SHA-1 ekleyin: $RELEASE_SHA"
echo "google-services.json yeniden indirin ve GOOGLE_SERVICES_JSON_BASE64 secret güncelleyin:"
echo "  bash scripts/set-google-services-secret.sh"
exit 1
