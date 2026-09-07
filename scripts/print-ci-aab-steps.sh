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
=== GitHub Actions — Build release AAB (${VERSION}) ===

1. Secrets (Settings → Secrets and variables → Actions):
   ANDROID_KEYSTORE_BASE64
   ANDROID_KEYSTORE_PASSWORD
   ANDROID_KEY_ALIAS
   ANDROID_KEY_PASSWORD
   (opsiyonel) GOOGLE_SERVICES_JSON_BASE64

   Rehber: bash scripts/play-keystore-secrets-cheatsheet.sh

2. Workflow çalıştır:
   ${WF}
   → Run workflow → branch: main

3. Bitince artifact indir:
   canlifal-release-aab → app-release.aab

4. Play Console → Closed testing → Create release → AAB yükle

Yerel (keystore varsa): bash scripts/build-play-aab.sh
Ön kontrol:            bash scripts/play-aab-readiness.sh

Workflow dosyası: .github/workflows/build-aab.yml
EOF
