#!/usr/bin/env bash
# Play Store AAB — GitHub keystore secret kurulum rehberi (terminal).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="mesutbyrm/Cursor-Flutter-"

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Play Store — keystore secret kurulumu                            ║
╚══════════════════════════════════════════════════════════════════╝

GitHub → ${REPO} → Settings → Secrets and variables → Actions

Zorunlu secret'lar (AAB + release APK imzası):
  ANDROID_KEYSTORE_BASE64      release.keystore dosyasının base64
  ANDROID_KEYSTORE_PASSWORD    keystore şifresi
  ANDROID_KEY_ALIAS            örn. canlifal-upload
  ANDROID_KEY_PASSWORD         key şifresi

Opsiyonel (Google Sign-In):
  GOOGLE_SERVICES_JSON_BASE64  google-services.json tam içerik

Keystore base64 (yerel makinede):
  base64 -w0 mobile/android/app/release.keystore | pbcopy   # macOS
  base64 -w0 mobile/android/app/release.keystore            # Linux

Yerel örnek:
  cp mobile/android/key.properties.example mobile/android/key.properties
  # release.keystore → mobile/android/app/

Secret sonrası AAB derle:
  Actions → Build release AAB → Run workflow → main
  Artifact: canlifal-release-aab

APK (apk-latest):
  Actions → Build release APK → Run workflow → main

Doğrulama:
  bash scripts/play-aab-readiness.sh
  bash scripts/verify-google-signin-config.sh

Detay: docs/GOOGLE_SIGNIN_FIX_SHA1_TR.md
       docs/PLAY_STORE_AGENT_CHECKLIST.md
EOF

bash "$ROOT/scripts/play-aab-readiness.sh" 2>&1 | sed 's/^/  /' || true
