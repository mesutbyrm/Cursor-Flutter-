#!/usr/bin/env bash
# Teknik bilgi gerektirmeyen özet — tüm API testlerini çalıştırır.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

echo "=============================================="
echo "  Canlifal — Otomatik testler başlıyor"
echo "=============================================="
echo ""

PASS_ALL=0
FAIL_ANY=0

run_one() {
  local name="$1" script="$2"
  echo ""
  echo ">>> $name"
  if bash "$script"; then
    echo "✅ $name — TAMAM"
    PASS_ALL=$((PASS_ALL + 1))
  else
    echo "❌ $name — SORUN VAR (detay yukarıda)"
    FAIL_ANY=$((FAIL_ANY + 1))
  fi
}

run_one "Temel API testleri" "scripts/acceptance-tests/api-final-phase.sh"
run_one "Stage 5 E2E (jeton/hediye/müzik)" "scripts/acceptance-tests/api-stage5-e2e.sh"
run_one "Engellenen maddeler (API)" "scripts/acceptance-tests/api-stage5-unblock.sh"

if command -v adb >/dev/null 2>&1 && adb devices 2>/dev/null | grep -qE 'device$'; then
  run_one "Telefon TRTC duman" "scripts/acceptance-tests/device-trtc-smoke.sh"
else
  echo ""
  echo "⏸️  Telefon testi atlandı — USB ile Android bağlı değil"
  echo "   Nasıl bağlanır: docs/KULLANICI_TEST_KILAVUZU.md"
fi

echo ""
echo "=============================================="
echo "  ÖZET"
echo "=============================================="
echo "  Geçen paket: $PASS_ALL"
echo "  Sorunlu paket: $FAIL_ANY"
echo ""
echo "  Detay raporlar:"
echo "    - docs/STAGE5_REAL_E2E_ACCEPTANCE_REPORT.md"
echo "    - docs/STAGE5_UNBLOCK_REPORT.md"
echo ""
if [[ "$FAIL_ANY" -gt 0 ]]; then
  echo "  ⚠️  Bazı testler başarısız veya BLOCKED."
  echo "  Sizin yapmanız gerekenler: docs/KULLANICI_TEST_KILAVUZU.md"
  exit 1
fi
echo "  ✅ Tüm otomatik API testleri geçti."
exit 0
