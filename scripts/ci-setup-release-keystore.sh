#!/usr/bin/env bash
# CI: ANDROID_* secret'larından release.keystore + key.properties oluştur ve doğrula.
# Secret değerlerini loga yazmaz.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEYSTORE_PATH="$ROOT/mobile/android/app/release.keystore"
KEY_PROPS="$ROOT/mobile/android/key.properties"
GS_JSON="$ROOT/mobile/android/app/google-services.json"
EXPECTED_PACKAGE="com.mesutbyrm.canlifal"

bash "$ROOT/scripts/ci-release-signing-preflight.sh"

mkdir -p "$(dirname "$KEYSTORE_PATH")"

B64=$(printf '%s' "$ANDROID_KEYSTORE_BASE64" | tr -d '\n\r\t ')
if ! printf '%s' "$B64" | base64 -d >"$KEYSTORE_PATH" 2>/tmp/keystore-decode.err; then
  echo "::error::ANDROID_KEYSTORE_BASE64 decode başarısız — geçerli base64 değil."
  exit 1
fi

if [[ ! -s "$KEYSTORE_PATH" ]]; then
  echo "::error::Decode sonrası release.keystore boş."
  exit 1
fi

# key.properties — değerler secret'tan; dosya yalnızca CI runner'da, commit edilmez.
{
  printf '%s\n' "storeFile=release.keystore"
  printf 'storePassword=%s\n' "$ANDROID_KEYSTORE_PASSWORD"
  printf 'keyAlias=%s\n' "$ANDROID_KEY_ALIAS"
  printf 'keyPassword=%s\n' "$ANDROID_KEY_PASSWORD"
} >"$KEY_PROPS"

if [[ ! -f "$KEY_PROPS" ]]; then
  echo "::error::key.properties oluşturulamadı."
  exit 1
fi

if ! command -v keytool >/dev/null 2>&1; then
  echo "::error::keytool bulunamadı (Java JDK gerekli)."
  exit 1
fi

KEYTOOL_OUT="$(mktemp)"
KEYTOOL_ERR="$(mktemp)"
if ! keytool -list -v \
  -keystore "$KEYSTORE_PATH" \
  -alias "$ANDROID_KEY_ALIAS" \
  -storepass "$ANDROID_KEYSTORE_PASSWORD" \
  >"$KEYTOOL_OUT" 2>"$KEYTOOL_ERR"; then
  echo "::error::release.keystore doğrulama başarısız — alias veya ANDROID_KEYSTORE_PASSWORD hatalı."
  sed 's/password/****/gi' "$KEYTOOL_ERR" | head -5 || true
  rm -f "$KEYTOOL_OUT" "$KEYTOOL_ERR"
  exit 1
fi

SHA1=$(grep -i 'SHA1:' "$KEYTOOL_OUT" | head -1 | sed 's/.*SHA1:[[:space:]]*//' | tr -d '[:space:]')
SHA256=$(grep -i 'SHA256:' "$KEYTOOL_OUT" | head -1 | sed 's/.*SHA256:[[:space:]]*//' | tr -d '[:space:]')
OWNER=$(grep -i 'Owner:' "$KEYTOOL_OUT" | head -1 | sed 's/.*Owner:[[:space:]]*//' || true)

rm -f "$KEYTOOL_OUT" "$KEYTOOL_ERR"

if echo "$OWNER" | grep -qi 'CN=Android Debug'; then
  echo "::error::Keystore debug sertifikası — release upload keystore kullanın."
  exit 1
fi

echo "Release keystore hazır."
echo "  path    : mobile/android/app/release.keystore"
echo "  alias   : $ANDROID_KEY_ALIAS"
echo "  SHA-1   : ${SHA1:-<alınamadı>}"
echo "  SHA-256 : ${SHA256:-<alınamadı>}"

normalize_sha() {
  echo "$1" | tr -d ':' | tr '[:upper:]' '[:lower:]'
}

if [[ -f "$GS_JSON" ]] && command -v jq >/dev/null 2>&1; then
  PKG=$(jq -r '.client[0].client_info.android_client_info.package_name // empty' "$GS_JSON")
  if [[ "$PKG" != "$EXPECTED_PACKAGE" ]]; then
    echo "::error::google-services.json package_name ($PKG) ≠ applicationId ($EXPECTED_PACKAGE)"
    exit 1
  fi
  echo "✓ google-services.json package_name: $PKG"

  REGISTERED_SHA=$(jq -r '.client[0].oauth_client[]? | select(.client_type == 1) | .android_info.certificate_hash // empty' "$GS_JSON" | head -1)
  if [[ -n "$REGISTERED_SHA" && -n "$SHA1" ]]; then
    LOCAL=$(normalize_sha "$SHA1")
    REG=$(normalize_sha "$REGISTERED_SHA")
    if [[ "$LOCAL" != "$REG" ]]; then
      echo "::error::Release keystore SHA-1, google-services.json certificate_hash ile eşleşmiyor."
      echo "  Keystore SHA-1 : $SHA1"
      echo "  JSON hash      : $REGISTERED_SHA"
      echo "  → Firebase Console → Android app → SHA-1 ekleyin veya GOOGLE_SERVICES_JSON_BASE64 güncelleyin."
      exit 1
    fi
    echo "✓ Release SHA-1 google-services.json certificate_hash ile eşleşiyor"
  else
    echo "::warning::google-services.json içinde Android OAuth certificate_hash yok — Google Sign-In riski."
  fi
else
  echo "::warning::google-services.json yok veya jq eksik — SHA-1 eşleşmesi atlandı."
fi

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "RELEASE_KEYSTORE_SHA1=$SHA1" >>"$GITHUB_ENV"
fi
