#!/usr/bin/env bash
# Release APK öncesi — dört keystore secret'ının varlığını kontrol eder (değerleri loglamaz).
set -euo pipefail

missing=()
[[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]] && missing+=(ANDROID_KEYSTORE_BASE64)
[[ -z "${ANDROID_KEYSTORE_PASSWORD:-}" ]] && missing+=(ANDROID_KEYSTORE_PASSWORD)
[[ -z "${ANDROID_KEY_ALIAS:-}" ]] && missing+=(ANDROID_KEY_ALIAS)
[[ -z "${ANDROID_KEY_PASSWORD:-}" ]] && missing+=(ANDROID_KEY_PASSWORD)

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "::error::Eksik GitHub Actions secret(s): ${missing[*]}"
  echo "::error::Release APK için dört secret zorunlu. Debug imza yasak."
  echo "Kurulum: docs/ANDROID_RELEASE_SIGNING_CI.md"
  echo "Settings → Secrets and variables → Actions"
  exit 1
fi

for name in ANDROID_KEYSTORE_BASE64 ANDROID_KEYSTORE_PASSWORD ANDROID_KEY_ALIAS ANDROID_KEY_PASSWORD; do
  if ! test -n "${!name}"; then
    echo "::error::Secret boş: $name"
    exit 1
  fi
done

echo "✓ Release signing secrets mevcut (ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD)"
