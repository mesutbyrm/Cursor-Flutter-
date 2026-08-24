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
echo "Kod otomasyonu tamamlandı (müzik ANR, PK, push teardown, sesli oda P0–P2, API voice seat probe)."
echo "Kalan iş yalnızca jeton + Android cihaz doğrulaması."
echo ""
echo "── Jeton olmadan API doğrulama ──"
echo "  bash scripts/run-voice-seat-acceptance.sh   # presence/koltuk/SSE"
echo "  bash scripts/run-music-acceptance.sh        # müzik (song-request jeton ister)"
echo ""
bash "$ROOT/scripts/admin-jeton-cheatsheet.sh" | tail -12
echo ""
echo "── Jeton eklendikten sonra ──"
echo "  bash scripts/after-admin-jeton.sh       # hemen dene"
echo "  bash scripts/wait-for-jeton.sh 10 3600  # otomatik bekle + M7"
echo ""
echo "── Cihaz checklist (10 test) ──"
echo "  docs/M5_DEVICE_TEST_CHECKLIST.md"
echo "    Test 1–3: müzik / !istek"
echo "    Test 4: oda değişimi (presence)"
echo "    Test 5–6: sesli + canlı PK"
echo "    Test 7–10: koltuk-ses, mod popup, self-seat, giriş şeridi (P0–P2)"
echo ""
