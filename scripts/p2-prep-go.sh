#!/usr/bin/env bash
# P2 prep GO — agent Play Store hazırlığı (cihaz sonucu beklemeden).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P2 prep GO — Play Store agent (${VERSION})                       ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Cihaz P0/P1 sonucu: SONRA · Console formları + AAB hazırlığı: ŞİMDİ"
echo ""

if [[ -f "$LOG" ]]; then
  if device_test_log_has_pass "Psychic P0" "$LOG"; then
    echo "✅ Psychic P0 PASS kayıtlı"
  else
    echo "⏳ Psychic P0 PASS yok (yükleme günü öncesi normal)"
  fi
  if device_test_log_has_pass "P1 Platform" "$LOG"; then
    echo "✅ P1 Platform PASS kayıtlı"
  else
    echo "⏸ P1 PASS yok (yükleme günü öncesi normal)"
  fi
  echo ""
fi

echo "── Hızlı kontrol ──"
bash "$ROOT/scripts/play-aab-readiness.sh" 2>&1 | grep -E '^(✅|⏳|❌|──)' | head -14 || true
echo ""

cat <<'EOF'
── Agent komutları ──
  bash scripts/p2-prep-all.sh                    # tam prep (tüm print metinleri)
  bash scripts/print-play-console-prep-index.sh  # betik indeksi
  bash scripts/play-store-checklist.sh           # Console checklist
  bash scripts/print-ci-aab-steps.sh             # GitHub Actions AAB
  bash scripts/play-keystore-secrets-cheatsheet.sh

── Cihaz (sonra) ──
  bash scripts/cihaz-sonra.sh
  bash scripts/p2-go.sh                          # P0+P1 PASS sonrası yükleme günü

Rehber: docs/PLAY_STORE_AGENT_CHECKLIST.md · docs/P2_PLAY_STORE_START.md
EOF
