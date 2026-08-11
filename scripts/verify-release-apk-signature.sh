#!/usr/bin/env bash
# APK release imzalı mı doğrular; CN=Android Debug ise başarısız.
set -euo pipefail

APK="${1:-}"
if [[ -z "$APK" || ! -f "$APK" ]]; then
  echo "::error::APK yolu geçersiz: ${APK:-<boş>}"
  exit 1
fi

if [[ ! -s "$APK" ]]; then
  echo "::error::APK dosyası boş: $APK"
  exit 1
fi

SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
APKSIGNER=""
if [[ -d "$SDK/build-tools" ]]; then
  APKSIGNER=$(find "$SDK/build-tools" -name apksigner -type f 2>/dev/null | sort -V | tail -1)
fi

CERT_LOG="$(mktemp)"

if [[ -n "$APKSIGNER" && -x "$APKSIGNER" ]]; then
  "$APKSIGNER" verify --print-certs "$APK" >"$CERT_LOG" 2>&1 || {
    echo "::error::apksigner verify başarısız"
    head -20 "$CERT_LOG"
    rm -f "$CERT_LOG"
    exit 1
  }
else
  if ! command -v jarsigner >/dev/null 2>&1; then
    echo "::error::apksigner ve jarsigner bulunamadı — APK imza doğrulanamadı."
    exit 1
  fi
  jarsigner -verify -verbose -certs "$APK" >"$CERT_LOG" 2>&1 || true
fi

if grep -qi 'CN=Android Debug' "$CERT_LOG"; then
  echo "::error::APK debug keystore (CN=Android Debug) ile imzalanmış — release build reddedildi."
  rm -f "$CERT_LOG"
  exit 1
fi

if grep -qi 'DEBUG' "$CERT_LOG" && grep -qi 'androiddebugkey' "$CERT_LOG"; then
  echo "::error::APK androiddebugkey ile imzalanmış görünüyor."
  rm -f "$CERT_LOG"
  exit 1
fi

# İlk sertifika özeti (şifre/private key yok)
grep -E '^(Signer|Owner|SHA1|SHA-256|SHA256)' "$CERT_LOG" | head -12 || head -8 "$CERT_LOG"

rm -f "$CERT_LOG"
echo "✓ APK release imza doğrulaması geçti (debug keystore değil): $APK"
