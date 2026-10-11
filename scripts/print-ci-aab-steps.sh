#!/usr/bin/env bash
# GitHub Actions — release AAB derleme adımları (kullanıcı).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="?"
if [[ -f "$ROOT/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

WF="https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-aab.yml"

cat <<EOF
=== Play Store AAB (${VERSION}) ===

Önerilen (otomatik — main CI sonrası APK workflow ile birlikte):
  https://github.com/mesutbyrm/Cursor-Flutter-/actions/workflows/build-apk.yml
  → Son başarılı run → Artifacts → canlifal-release-aab-${VERSION} → app-release.aab

Manuel yalnızca AAB:
  ${WF}
  → Run workflow → branch: main
  → Artifact: canlifal-release-aab

Secrets (APK/AAB ortak):
  ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD,
  ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD
  Rehber: bash scripts/play-keystore-secrets-cheatsheet.sh

Play Console → Testing / Production → Create release → AAB yükle

Yerel (keystore varsa): bash scripts/build-play-aab.sh
Ön kontrol:            bash scripts/play-aab-readiness.sh
EOF
