#!/usr/bin/env bash
# CI — Flutter flutter.ndkVersion ile aynı NDK sürümünü sdkmanager ile kurar.
# nttld + yanlış sürüm symlink'i (27.0 → 27.3 uyarısı) kullanılmaz.
set -euo pipefail

# GHA runner'da kalmış eski NDK path (silinmiş 27.x symlink) yeni kurulumu bozmasın.
unset ANDROID_NDK_HOME ANDROID_NDK_ROOT ANDROID_NDK_VERSION || true

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
  echo "Android SDK bulunamadı (ANDROID_HOME / ANDROID_SDK_ROOT)" >&2
  exit 1
}

resolve_ndk_version_from_flutter() {
  if [ -n "${ANDROID_NDK_VERSION:-}" ]; then
    echo "$ANDROID_NDK_VERSION"
    return
  fi
  if ! command -v flutter >/dev/null 2>&1; then
    echo "flutter komutu yok — önce Flutter kurulum adımını çalıştırın." >&2
    exit 1
  fi
  local flutter_root
  flutter_root="$(dirname "$(dirname "$(command -v flutter)")")"
  local gradle_utils="${flutter_root}/packages/flutter_tools/lib/src/android/gradle_utils.dart"
  if [ -f "$gradle_utils" ]; then
    local detected
    detected="$(grep -E "^const ndkVersion = " "$gradle_utils" | sed -E "s/.*'([^']+)'.*/\1/" || true)"
    if [ -n "$detected" ]; then
      echo "$detected"
      return
    fi
  fi
  local ext="${flutter_root}/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt"
  if [ -f "$ext" ]; then
    local detected
    detected="$(grep -E 'val ndkVersion: String = "' "$ext" | sed -E 's/.*"([0-9.]+)".*/\1/' || true)"
    if [ -n "$detected" ]; then
      echo "$detected"
      return
    fi
  fi
  echo "Flutter ndkVersion tespit edilemedi" >&2
  exit 1
}

find_sdkmanager() {
  local sdk="$1"
  if [ -x "${sdk}/cmdline-tools/latest/bin/sdkmanager" ]; then
    echo "${sdk}/cmdline-tools/latest/bin/sdkmanager"
    return
  fi
  if [ -x "${sdk}/cmdline-tools/bin/sdkmanager" ]; then
    echo "${sdk}/cmdline-tools/bin/sdkmanager"
    return
  fi
  echo "sdkmanager bulunamadı: ${sdk}/cmdline-tools/latest/bin/sdkmanager" >&2
  exit 1
}

ndk_revision_at_path() {
  local props="$1/source.properties"
  if [ ! -f "$props" ]; then
    return 1
  fi
  grep -E '^Pkg.Revision\s*=' "$props" | awk '{print $3}' | tr -d '\r'
}

clean_stale_ndk_installs() {
  local sdk="$1"
  local expected="$2"
  local ndk_root="${sdk}/ndk"
  mkdir -p "$ndk_root"
  shopt -s nullglob
  for dir in "${ndk_root}"/*; do
    [ -d "$dir" ] || continue
    local base
    base="$(basename "$dir")"
    local rev=""
    rev="$(ndk_revision_at_path "$dir" 2>/dev/null || true)"
    if [ "$base" != "$expected" ] || [ "$rev" != "$expected" ]; then
      echo "Eski/uyumsuz NDK kaldırılıyor: $dir (rev=${rev:-yok}, beklenen=$expected)"
      rm -rf "$dir"
    fi
  done
  shopt -u nullglob
}

ANDROID_SDK="$(resolve_android_sdk)"
export ANDROID_HOME="$ANDROID_SDK"
export ANDROID_SDK_ROOT="$ANDROID_SDK"

NDK_VER="$(resolve_ndk_version_from_flutter)"
echo "Flutter NDK sürümü: $NDK_VER"

clean_stale_ndk_installs "$ANDROID_SDK" "$NDK_VER"

NDK_PATH="${ANDROID_SDK}/ndk/${NDK_VER}"
if [ -d "$NDK_PATH" ] && [ "$(ndk_revision_at_path "$NDK_PATH" || echo "")" = "$NDK_VER" ]; then
  echo "NDK zaten kurulu: $NDK_PATH"
else
  rm -rf "$NDK_PATH"
  SDKMANAGER="$(find_sdkmanager "$ANDROID_SDK")"
  echo "sdkmanager ile kuruluyor: ndk;${NDK_VER}"
  yes | "$SDKMANAGER" --licenses >/dev/null 2>&1 || true
  "$SDKMANAGER" --install "ndk;${NDK_VER}"
fi

if [ ! -f "$NDK_PATH/source.properties" ]; then
  echo "NDK kurulumu doğrulanamadı: $NDK_PATH" >&2
  exit 1
fi
INSTALLED_REV="$(ndk_revision_at_path "$NDK_PATH")"
if [ "$INSTALLED_REV" != "$NDK_VER" ]; then
  echo "NDK sürüm uyumsuz: klasör=$NDK_VER source.properties=$INSTALLED_REV" >&2
  exit 1
fi

export ANDROID_NDK_HOME="$NDK_PATH"
export ANDROID_NDK_ROOT="$NDK_PATH"

ENV_FILE="${CI_ANDROID_NDK_ENV_FILE:-${GITHUB_WORKSPACE:-/tmp}/.ci-android-ndk.env}"
mkdir -p "$(dirname "$ENV_FILE")"
cat >"$ENV_FILE" <<EOF
ANDROID_HOME=$ANDROID_SDK
ANDROID_SDK_ROOT=$ANDROID_SDK
ANDROID_NDK_HOME=$NDK_PATH
ANDROID_NDK_ROOT=$NDK_PATH
ANDROID_NDK_VERSION=$NDK_VER
EOF

if [ -n "${GITHUB_ENV:-}" ]; then
  while IFS= read -r line; do
    echo "$line" >>"$GITHUB_ENV"
  done <"$ENV_FILE"
fi

echo "NDK hazır: ANDROID_NDK_HOME=$ANDROID_NDK_HOME"
echo "NDK env dosyası: $ENV_FILE"
