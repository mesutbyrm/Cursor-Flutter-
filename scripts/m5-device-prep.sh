#!/usr/bin/env bash
# M5 Android cihaz testi — hazırlık özeti + otomatik kapılar.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | awk '{print $2}')

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  M5 cihaz hazırlık — Flutter $VERSION"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "APK: https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
echo "Hesap: cursor.test.1786235468@mailinator.com"
echo "Oda: cmoohrbr (SSE: cmoohrbrx00a4nt08zlkdjyil)"
echo "Komut: !istek Tarkan - Şımarık"
echo "PK testleri: Test 5–6 (sesli + canlı PK)"
echo "Sesli oda P0–P2: Test 7–10 (koltuk-ses, mod popup, self-seat, giriş şeridi)"
echo ""
echo "Checklist: docs/M5_DEVICE_TEST_CHECKLIST.md"
echo ""

bash "$ROOT/scripts/admin-jeton-cheatsheet.sh" 2>/dev/null | tail -8
echo ""

if bash "$ROOT/scripts/m5-ready.sh" 2>/dev/null; then
  echo ""
  echo "✅ Otomatik kapılar hazır — cihaz testine geçin"
  exit 0
fi

echo ""
echo "⚠️  m5-preflight jeton bekliyor — önce admin panelden jeton ekleyin"
exit 1
