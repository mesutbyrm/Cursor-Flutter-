#!/usr/bin/env bash
# Google Play production AAB — R8 + Dart obfuscation + split debug info.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/mobile"

export ANDROID_HOME="${ANDROID_HOME:-/opt/android-sdk}"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:${PATH:-}"

flutter pub get
flutter build appbundle --release \
  --tree-shake-icons \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols

echo "AAB: mobile/build/app/outputs/bundle/release/app-release.aab"
ls -lh build/app/outputs/bundle/release/app-release.aab
