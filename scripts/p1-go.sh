#!/usr/bin/env bash
# P1 — GO ekranı: P0 PASS sonrası platform cihaz testi.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P1 GO — platform 2-cihaz (${VERSION})                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "APK: $APK_URL"
echo ""

if device_test_log_has_pass "Psychic P0" "$LOG"; then
  echo "✅ Psychic P0 PASS kaydı bulundu (USER_DEVICE_TEST_LOG.md)"
else
  echo "⚠️  Psychic P0 PASS kaydı yok — önce:"
  echo "   bash scripts/on-p0-pass.sh"
  echo ""
fi

cat <<'EOF'
Hesaplar (2 cihaz veya A/B):
  Cihaz A → cursor.test.1786235468@mailinator.com  (danışan / izleyici)
  Cihaz B → cursor.host.1786235468@mailinator.com  (host / oda sahibi)
  Şifre   → CursorTest!1786235468

Alanlar: sesli oda · hediye · PK · müzik · mesaj · oturum izolasyonu

Checklist:
  bash scripts/p1-platform-checklist.sh
  bash scripts/print-full-user-checklist.sh   # P0+P1 birleşik

Müzik (M5): docs/M5_DEVICE_TEST_CHECKLIST.md
  bash scripts/m5-device-prep.sh

Sonuç:
  PASS → bash scripts/on-p1-pass.sh
  FAIL → bash scripts/record-user-test-result.sh p1 FAIL "hangi satır"

P1 PASS sonrası:
  bash scripts/on-release-ready-candidate.sh

EOF
