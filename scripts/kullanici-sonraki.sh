#!/usr/bin/env bash
# Kullanıcı — release için kalan adımlar (agent prep tamam).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "$ROOT/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Kullanıcı — sonraki adımlar (${VERSION})                         ║
╚══════════════════════════════════════════════════════════════════╝

Agent prep: ✅ TAMAM (bash scripts/agent-prep-tamam.sh)
RELEASE READY: NO — aşağıdaki 3 blok sizde

APK: ${APK_URL}

── 1) Cihaz testleri (sonra) ──
  bash scripts/cihaz-sonra.sh
  bash scripts/p0-go.sh → user-test-start.sh p0
  bash scripts/on-p0-pass.sh → p1-go.sh → on-p1-pass.sh

── 2) Keystore + AAB ──
  GitHub Secrets: ANDROID_KEYSTORE_*
  bash scripts/play-keystore-secrets-cheatsheet.sh
  bash scripts/print-ci-aab-steps.sh
  Actions → Build release AAB

── 3) Play Console (P0+P1 PASS sonrası) ──
  bash scripts/print-play-upload-day-checklist.sh
  bash scripts/p2-go.sh

Özet: bash scripts/print-release-blockers.sh
Detay: docs/RELEASE_USER_NEXT_STEPS.md
EOF

bash "$ROOT/scripts/agent-prep-tamam.sh" 2>&1 | tail -4 || true
