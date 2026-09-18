#!/usr/bin/env bash
# CI — Flutter doctor, Java, SDK/NDK sürümlerini build öncesi doğrular.
set -euo pipefail

echo "=== Java ==="
java -version

echo "=== Flutter ==="
flutter --version
DOCTOR_OUT="$(flutter doctor -v 2>&1 || true)"
echo "$DOCTOR_OUT"
if ! echo "$DOCTOR_OUT" | grep -Fq 'Android toolchain - develop for Android devices'; then
  echo "HATA: Android toolchain görünmüyor" >&2
  exit 1
fi
if echo "$DOCTOR_OUT" | grep -F 'Android toolchain - develop for Android devices' | grep -Fq '[✗]'; then
  echo "HATA: Android toolchain başarısız" >&2
  exit 1
fi

ANDROID_SDK="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-/usr/local/lib/android/sdk}}"
echo "=== Android SDK ==="
echo "ANDROID_HOME=$ANDROID_SDK"
echo "ANDROID_NDK_HOME=${ANDROID_NDK_HOME:-<unset>}"

if [ -n "${ANDROID_NDK_VERSION:-}" ]; then
  echo "ANDROID_NDK_VERSION=$ANDROID_NDK_VERSION"
fi

if [ -d "${ANDROID_SDK}/ndk" ]; then
  echo "=== ndk/ dizini ==="
  ls -la "${ANDROID_SDK}/ndk" || true
fi

if [ -n "${ANDROID_NDK_HOME:-}" ] && [ -f "${ANDROID_NDK_HOME}/source.properties" ]; then
  echo "=== ANDROID_NDK_HOME source.properties ==="
  cat "${ANDROID_NDK_HOME}/source.properties"
  rev="$(grep -E '^Pkg.Revision' "${ANDROID_NDK_HOME}/source.properties" | awk '{print $3}' | tr -d '\r')"
  base="$(basename "$ANDROID_NDK_HOME")"
  if [ "$rev" != "$base" ]; then
    echo "HATA: NDK path adı ($base) Pkg.Revision ($rev) ile eşleşmiyor" >&2
    exit 1
  fi
else
  echo "UYARI: ANDROID_NDK_HOME veya source.properties yok" >&2
  exit 1
fi

echo "NDK doğrulama OK"
