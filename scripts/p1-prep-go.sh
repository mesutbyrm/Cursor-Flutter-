#!/usr/bin/env bash
# P1 prep GO — platform checklist hazırlığı (P0 sonucu sonra kaydedilebilir).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P1 prep GO — platform checklist (${VERSION})                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "P0 sonucu: SONRA kaydedilebilir · P1 checklist: ŞİMDİ hazırlanabilir"
echo ""
echo "APK: ${APK_URL}"
echo ""

if [[ -f "$LOG" ]]; then
  if device_test_log_has_pass "Psychic P0" "$LOG"; then
    echo "✅ Psychic P0 PASS kayıtlı — P1 cihaz testine geçilebilir"
  else
    echo "⏳ Psychic P0 PASS yok — checklist şimdiden kullanılabilir"
  fi
  echo ""
fi

bash "$ROOT/scripts/p1-prep-now.sh" 2>&1 | head -28

cat <<'EOF'

── P0 sonucu gelince ──
  bash scripts/on-p0-pass.sh
  bash scripts/p1-go.sh

── P1 bittikten sonra ──
  bash scripts/on-p1-pass.sh
  bash scripts/on-release-ready-candidate.sh

Agent P2 (paralel): bash scripts/p2-prep-go.sh
Detay: docs/P1_DEVICE_START.md · docs/M5_DEVICE_TEST_CHECKLIST.md
EOF
