#!/usr/bin/env bash
# P0 + P1 PASS sonrası — RELEASE READY adayı kontrol listesi (kullanıcı onayı).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  RELEASE READY adayı — kontrol listesi                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

if [[ -f "$LOG" ]]; then
  echo "── Kayıtlı test sonuçları (USER_DEVICE_TEST_LOG) ──"
  grep -E 'Psychic P0|P1 Platform' "$LOG" | tail -6 || echo "(henüz kayıt yok)"
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

Sonraki (P2 backlog):
  docs/P2_PLAY_STORE_START.md
  bash scripts/build-play-aab.sh   # keystore secret gerekir

EOF

bash "$ROOT/scripts/release-remaining-status.sh" 2>&1 | grep -E 'RELEASE READY|Agent|P0 ·|P1 ·' || true
