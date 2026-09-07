#!/usr/bin/env bash
# P2 Play Store — cihaz sonucu beklemeden agent hazırlığı.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
VERSION="?"
BUILD="?"
if [[ -f "$MOBILE/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$MOBILE/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
  BUILD="${VERSION#*+}"
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P2 hazırlık — agent (${VERSION})                                 ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Agent prep: ✅ TAMAM · referans print betikleri"
echo "Cihaz P0/P1 sonucu: SONRA · Yükleme: print-play-upload-day-checklist.sh"
echo ""

# Sürüm / paket
APP_ID=$(grep -E 'applicationId' "$MOBILE/android/app/build.gradle.kts" 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/' || \
  grep -E 'applicationId' "$MOBILE/android/app/build.gradle" 2>/dev/null | head -1 | sed 's/.*"\(.*\)".*/\1/' || echo "com.mesutbyrm.canlifal")
echo "── Uygulama ──"
echo "  applicationId: $APP_ID"
echo "  version:       $VERSION (build $BUILD)"
echo "  API:           https://canlifal.com"
echo ""

# Keystore
echo "── Release imza (Play yükleme) ──"
if [[ -f "$MOBILE/android/key.properties" ]]; then
  echo "  ✅ mobile/android/key.properties (yerel)"
else
  echo "  ⏳ key.properties yok — CI secret veya yerel KEYSTORE_CREDENTIALS"
  echo "     Örnek: mobile/android/key.properties.example"
fi
if [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  echo "  ✅ ANDROID_KEYSTORE_BASE64 (ortam)"
else
  echo "  ⏳ ANDROID_KEYSTORE_BASE64 secret yok (GitHub Actions)"
fi
echo "  AAB: bash scripts/build-play-aab.sh"
echo ""

# Google Sign-In (Play / Firebase)
echo "── Google Sign-In ──"
if [[ -x "$ROOT/scripts/verify-google-signin-config.sh" ]]; then
  bash "$ROOT/scripts/verify-google-signin-config.sh" 2>&1 | grep -E '^(✓|✅|❌|⚠|  )' | head -12 || echo "  ℹ️  Google Sign-In: docs/GOOGLE_SIGNIN_SETUP_TR.md"
else
  echo "  bash scripts/verify-google-signin-config.sh"
fi
echo ""

# Play Console hazır metin
echo "── Play Console (kullanıcı — P0+P1 sonrası yükleme) ──"
echo "  App access test hesapları:"
echo "    cursor.test.1786235468@mailinator.com"
echo "    cursor.host.1786235468@mailinator.com"
echo "  Closed test track → AAB yükle → tester davet"
echo ""

echo "── Rehberler ──"
echo "  docs/P2_PLAY_STORE_START.md"
echo "  docs/PLAY_STORE_PRODUCTION_ACCESS.md"
echo "  docs/STAGE8_FINAL_ACCEPTANCE_REPORT.md"
echo "  docs/PLAY_FOREGROUND_SERVICE_DECLARATION.md"
echo ""

echo "── AAB readiness ──"
bash "$ROOT/scripts/play-aab-readiness.sh" 2>&1 | sed 's/^/  /'
echo ""
echo "Tam Console checklist: bash scripts/play-store-checklist.sh"
echo "P2 tam prep:           bash scripts/p2-prep-all.sh"
echo "Keystore secret:       bash scripts/play-keystore-secrets-cheatsheet.sh"
echo "App access metni:      bash scripts/print-play-console-app-access.sh"
echo "FGS metni:             bash scripts/print-play-foreground-service-declaration.sh"
echo "Data safety özeti:     bash scripts/print-play-data-safety-summary.sh"
bash "$ROOT/scripts/release-remaining-status.sh" 2>&1 | grep -E 'P2 ·|RELEASE READY' || true
