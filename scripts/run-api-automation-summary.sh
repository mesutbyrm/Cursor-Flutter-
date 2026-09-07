#!/usr/bin/env bash
# Otomatik API doğrulama özeti (jeton sonrası — cihaz testi ayrı).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Otomatik API özeti (jeton sonrası) ==="
echo ""

run() {
  local name="$1" cmd="$2"
  echo "── $name ──"
  if eval "$cmd" 2>&1 | tail -8; then
    echo ""
  else
    echo "(exit $?)"
    echo ""
  fi
}

run "Psychic P0 önkoşul" "bash '$ROOT/scripts/psychic-p0-prereqs.sh'"
run "M5 preflight" "bash '$ROOT/scripts/m5-preflight.sh'"
run "M5 API smoke" "bash '$ROOT/scripts/m5-api-smoke.sh'"
run "M7 song-request" "bash '$ROOT/scripts/m7-on-jeton.sh'"

echo "── Cihaz (kullanıcı — sonra) ──"
echo "  Psychic P0: bash scripts/psychic-p0-all.sh"
echo "  P1: bash scripts/p1-platform-checklist.sh"
echo "  M5 cihaz: docs/M5_DEVICE_TEST_CHECKLIST.md"
echo ""
echo "Raporlar: docs/M7_MUSIC_SSE_CAPTURE.md · docs/M5_API_SMOKE_REPORT.md"
