#!/usr/bin/env bash
# Google Play production AAB — R8 + Dart obfuscation + split debug info.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/mobile"

export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:${PATH:-}"

if [[ ! -f "$ROOT/mobile/android/key.properties" ]] && [[ -z "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "❌ Release keystore yok."
  echo "   Yerel: cp mobile/android/key.properties.example mobile/android/key.properties"
  echo "   CI: GitHub Actions → Build release AAB (ANDROID_KEYSTORE_* secrets)"
  bash "$ROOT/scripts/play-aab-readiness.sh" || true
  exit 1
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "❌ Flutter SDK yok — yerelde AAB derlenemez."
  echo "   CI: https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-aab.yml"
  exit 1
fi

flutter pub get
flutter build appbundle --release \
  --tree-shake-icons \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

echo "AAB: mobile/build/app/outputs/bundle/release/app-release.aab"
ls -lh build/app/outputs/bundle/release/app-release.aab
