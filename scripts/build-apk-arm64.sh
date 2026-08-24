#!/usr/bin/env bash
# arm64-only release APK — universal'dan ~%30–40 daha küçük indirme.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/mobile"

DEFINES=""
if [[ -f android/app/google-services.json ]]; then
  DEFINES=$(bash ../scripts/print-firebase-dart-defines.sh || true)
fi

# shellcheck disable=SC2086
flutter build apk --release \
  --target-platform android-arm64 \
  --tree-shake-icons \
  --obfuscate \
  --split-debug-info=build/app/outputs/symbols \
  $DEFINES

OUT="$ROOT/canlifal-mobile-arm64-release.apk"
cp build/app/outputs/flutter-apk/app-release.apk "$OUT"
ls -lh "$OUT"
echo "OK: $OUT"
