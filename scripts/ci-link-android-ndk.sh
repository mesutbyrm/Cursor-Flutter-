#!/usr/bin/env bash
# Flutter Gradle'ın beklediği ndk/<sürüm> yoluna ANDROID_NDK_HOME bağlar.
set -euo pipefail

resolve_android_sdk() {
  if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
    echo "$ANDROID_HOME"
    return
  fi
  if [ -n "${ANDROID_SDK_ROOT:-}" ] && [ -d "$ANDROID_SDK_ROOT" ]; then
    echo "$ANDROID_SDK_ROOT"
    return
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
  if [ -n "${ANDROID_NDK_VERSION:-}" ]; then
    echo "$ANDROID_NDK_VERSION"
    return
  fi
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
  echo "27.0.12077973"
}

if [ -z "${ANDROID_NDK_HOME:-}" ] || [ ! -d "$ANDROID_NDK_HOME" ]; then
  echo "ANDROID_NDK_HOME ayarlı değil — setup-ndk adımından sonra çalıştırın." >&2
  exit 1
fi

ANDROID_SDK="$(resolve_android_sdk)"
NDK_VER="$(resolve_ndk_version)"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"

mkdir -p "$ANDROID_SDK/ndk"
ln -sfn "$ANDROID_NDK_HOME" "$ANDROID_SDK/ndk/$NDK_VER"

if [ ! -f "$ANDROID_SDK/ndk/$NDK_VER/source.properties" ]; then
  echo "NDK symlink doğrulanamadı: $ANDROID_SDK/ndk/$NDK_VER" >&2
  exit 1
fi

echo "NDK bağlandı: $ANDROID_SDK/ndk/$NDK_VER -> $ANDROID_NDK_HOME"
