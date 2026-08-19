#!/usr/bin/env bash
# FAZ 0 agent → kullanıcı devir teslimi (jeton + M5 cihaz).
# Kullanım: bash scripts/faz0-handoff.sh [--verify]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${1:-}" == "--verify" ]]; then
  echo "── Tam otomatik doğrulama (faz0-verify) ──"
  bash "$ROOT/scripts/faz0-verify.sh"
  echo ""
fi

bash "$ROOT/scripts/faz0-status.sh"
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Kullanıcı devir teslimi — manuel adımlar                ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Kod otomasyonu tamamlandı (müzik ANR, PK, push/bildirim teardown, hata UX)."
echo "Kalan iş yalnızca jeton + Android cihaz doğrulaması."
echo ""
bash "$ROOT/scripts/admin-jeton-cheatsheet.sh" | tail -12
echo ""
echo "── Jeton eklendikten sonra ──"
echo "  bash scripts/after-admin-jeton.sh       # hemen dene"
echo "  bash scripts/wait-for-jeton.sh 10 3600  # otomatik bekle + M7"
echo ""
echo "── Cihaz checklist (6 test) ──"
echo "  docs/M5_DEVICE_TEST_CHECKLIST.md"
echo "    Test 1–3: müzik / !istek"
echo "    Test 4: oda değişimi (presence)"
echo "    Test 5–6: sesli + canlı PK"
echo ""
