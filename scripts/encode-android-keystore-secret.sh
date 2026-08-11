#!/usr/bin/env bash
# Yerel release.keystore → GitHub secret ANDROID_KEYSTORE_BASE64 (tek satır).
# Kullanım: bash scripts/encode-android-keystore-secret.sh mobile/android/app/release.keystore
set -euo pipefail

FILE="${1:-}"
if [[ -z "$FILE" || ! -f "$FILE" ]]; then
  echo "Kullanım: $0 <release.keystore yolu>" >&2
  exit 1
fi

if ! command -v base64 >/dev/null 2>&1; then
  echo "base64 gerekli" >&2
  exit 1
fi

echo "Aşağıdaki tek satırı GitHub → Settings → Secrets → ANDROID_KEYSTORE_BASE64 olarak ekleyin:"
echo ""
base64 -w0 "$FILE" 2>/dev/null || base64 "$FILE" | tr -d '\n'
echo ""
echo ""
echo "Diğer secret'lar: ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD"
echo "Ayrıntı: docs/ANDROID_RELEASE_SIGNING_CI.md"
