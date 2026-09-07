#!/usr/bin/env bash
# Release AAB öncesi hazırlık kontrolü (imza + Gradle + sürüm).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
ANDROID="$MOBILE/android"
ok=0 warn=0

check() {
  local st="$1" msg="$2"
  if [[ "$st" == ok ]]; then
    echo "✅ $msg"
    ok=$((ok + 1))
  else
    echo "⏳ $msg"
    warn=$((warn + 1))
  fi
}

VERSION="?"
BUILD="?"
if [[ -f "$MOBILE/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$MOBILE/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
  BUILD="${VERSION#*+}"
fi

echo "=== AAB readiness (${VERSION}) ==="
echo ""

[[ -f "$MOBILE/pubspec.yaml" ]] && check ok "pubspec.yaml sürüm: $VERSION" || check fail "pubspec.yaml yok"
[[ -f "$ANDROID/app/build.gradle.kts" || -f "$ANDROID/app/build.gradle" ]] && check ok "Android Gradle yapılandırması" || check fail "build.gradle yok"

if [[ -f "$ANDROID/key.properties" ]]; then
  check ok "key.properties (yerel)"
elif [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  check ok "ANDROID_KEYSTORE_BASE64 (CI ortam)"
else
  check fail "Release keystore yok — key.properties, CI secret veya Actions: Build release AAB"
fi

if [[ -f "$ANDROID/app/release.keystore" ]]; then
  check ok "release.keystore dosyası"
elif [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  check ok "Keystore CI secret ile türetilebilir"
else
  check fail "release.keystore yok (android/app/)"
fi

if command -v flutter >/dev/null 2>&1; then
  check ok "Flutter SDK: $(flutter --version 2>/dev/null | head -1)"
else
  check fail "Flutter SDK yok — AAB yerelde derlenemez (CI kullanın)"
fi

if [[ -f "$MOBILE/android/app/google-services.json" ]]; then
  check ok "google-services.json"
else
  check fail "google-services.json eksik"
fi

if [[ -x "$ROOT/scripts/verify-google-signin-config.sh" ]]; then
  if bash "$ROOT/scripts/verify-google-signin-config.sh" >/dev/null 2>&1; then
    check ok "Google Sign-In doğrulama"
  else
    check fail "Google Sign-In — bash scripts/verify-google-signin-config.sh"
  fi
fi

echo ""
if [[ "$warn" -eq 0 ]]; then
  echo "✅ AAB derlemeye hazır — bash scripts/build-play-aab.sh"
  exit 0
fi
echo "⏳ $warn madde eksik — Play yükleme öncesi tamamlayın"
echo "   Örnek: cp mobile/android/key.properties.example mobile/android/key.properties"
exit 0
