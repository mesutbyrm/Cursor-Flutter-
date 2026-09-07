#!/usr/bin/env bash
# P0 + P1 PASS sonrası — RELEASE READY adayı kontrol listesi (kullanıcı onayı).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  RELEASE READY adayı — kontrol listesi                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if [[ -f "$LOG" ]]; then
  echo "── Kayıtlı test sonuçları (USER_DEVICE_TEST_LOG) ──"
  ENTRIES=$(device_test_log_recent_entries "$LOG" || true)
  if [[ -n "$ENTRIES" ]]; then
    echo "$ENTRIES"
  else
    echo "(henüz kayıt yok — ## … — Psychic P0 **PASS** formatında)"
  fi
  echo ""
  if device_test_log_has_pass "Psychic P0" "$LOG"; then
    echo "✅ Psychic P0 PASS kayıtlı"
  else
    echo "⏳ Psychic P0 PASS kaydı yok"
  fi
  if device_test_log_has_pass "P1 Platform" "$LOG"; then
    echo "✅ P1 Platform PASS kayıtlı"
  else
    echo "⏸ P1 Platform PASS kaydı yok"
  fi
  echo ""
else
  echo "⚠️  Henüz test kaydı yok — önce:"
  echo "   bash scripts/on-p0-pass.sh"
  echo "   bash scripts/on-p1-pass.sh"
  echo ""
fi

cat <<'EOF'
Manuel onay (siz doğruladınız mı?):

  [ ] Psychic P0 PASS — T+5s donma yok, 2 telefon (danışan + falcı)
  [ ] P1 PASS — voice, hediye, PK, müzik, oturum izolasyonu
  [ ] Falcı: cursor.host.* ile test edildi (onaylı ✅)

Agent'a bildirin (kopyala-yapıştır):
  P0 PASS + P1 PASS — RELEASE READY adayı

Sonraki (P2 yükleme günü):
  bash scripts/print-play-upload-day-checklist.sh
  bash scripts/p2-go.sh
  bash scripts/print-ci-aab-steps.sh
  bash scripts/print-release-blockers.sh
  bash scripts/build-play-aab.sh   # keystore secret gerekir

Agent prep (şimdi): bash scripts/print-agent-prep-status.sh

EOF

bash "$ROOT/scripts/release-remaining-status.sh" 2>&1 | grep -E 'RELEASE READY|Agent|P0 ·|P1 ·' || true
