#!/usr/bin/env bash
# CodeQL / CI — Flutter'ın istediği Android NDK sürümünü kurar.
# Gradle otomatik indirmede "ZipFile unknown archive" hatasına karşı ön kurulum + retry.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

resolve_android_sdk() {
  if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
    echo "$ANDROID_HOME"
    return
  fi
  if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
    echo "$ANDROID_SDK_ROOT"
    return
  fi
  if command -v flutter >/dev/null 2>&1; then
    local from_flutter
    from_flutter="$(flutter doctor -v 2>/dev/null | sed -n 's/.*Android SDK at \(.*\)$/\1/p' | head -1 || true)"
    if [ -n "$from_flutter" ] && [ -d "$from_flutter" ]; then
      echo "$from_flutter"
      return
    fi
  fi
  for candidate in /usr/local/lib/android/sdk "$HOME/Android/Sdk"; do
    if [ -d "$candidate" ]; then
      echo "$candidate"
      return
    fi
  done
  echo "Android SDK bulunamadı" >&2
  exit 1
}

resolve_ndk_version() {
  local flutter_root=""
  if command -v flutter >/dev/null 2>&1; then
    flutter_root="$(dirname "$(dirname "$(command -v flutter)")")"
  fi
  if [ -n "$flutter_root" ] && [ -d "$flutter_root/packages/flutter_tools/gradle" ]; then
    local detected
    detected="$(
      grep -rhoE 'ndkVersion\s*=\s*"[0-9]+\.[0-9]+\.[0-9]+"' \
        "$flutter_root/packages/flutter_tools/gradle" 2>/dev/null \
        | head -1 \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \
        || true
    )"
    if [ -n "$detected" ]; then
      echo "$detected"
      return
    fi
  fi
  # Flutter 3.44 stable varsayılanı
  echo "27.0.12077973"
}

ANDROID_SDK="$(resolve_android_sdk)"
NDK_VER="$(resolve_ndk_version)"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"

SDKMANAGER="$ANDROID_SDK/cmdline-tools/latest/bin/sdkmanager"
if [ ! -x "$SDKMANAGER" ]; then
  SDKMANAGER="$(find "$ANDROID_SDK" -name sdkmanager -type f 2>/dev/null | head -1 || true)"
fi
if [ -z "$SDKMANAGER" ] || [ ! -x "$SDKMANAGER" ]; then
  echo "sdkmanager bulunamadı ($ANDROID_SDK)" >&2
  exit 1
fi

NDK_DIR="$ANDROID_SDK/ndk/$NDK_VER"
if [ -d "$NDK_DIR" ] && [ -f "$NDK_DIR/source.properties" ]; then
  echo "NDK $NDK_VER zaten kurulu: $NDK_DIR"
  exit 0
fi

echo "NDK $NDK_VER kuruluyor (SDK: $ANDROID_SDK)"
yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true

install_ok=false
for attempt in 1 2 3; do
  echo "NDK kurulum denemesi $attempt/3"
  rm -rf "$NDK_DIR" "$ANDROID_SDK/.temp/PackageOperation"* 2>/dev/null || true
  if yes | "$SDKMANAGER" --install "ndk;$NDK_VER"; then
    if [ -d "$NDK_DIR" ]; then
      install_ok=true
      break
    fi
  fi
  sleep "$((attempt * 5))"
done

if [ "$install_ok" != true ]; then
  echo "NDK $NDK_VER kurulamadı" >&2
  exit 1
fi

echo "NDK kuruldu: $NDK_DIR"
