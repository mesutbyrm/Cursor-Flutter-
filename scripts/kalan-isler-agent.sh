#!/usr/bin/env bash
# Agent kalan işler — cihaz testi sonraya bırakıldığında paralel hazırlık.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Agent kalan işler (cihaz testi SONRA)                            ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

fail=0
run() {
  local t="$1" c="$2"
  echo "── $t ──"
  if eval "$c"; then
    echo ""
  else
    echo "⚠️  $t — kısmi uyarı"
    fail=$((fail + 1))
    echo ""
  fi
}

run "Canlı API + jeton + falcı" "bash '$ROOT/scripts/psychic-p0-prereqs.sh' 2>&1 | tail -8"
run "API otomasyon özeti" "bash '$ROOT/scripts/run-api-automation-summary.sh' 2>&1 | tail -10"
run "P1 checklist (ön hazırlık)" "bash '$ROOT/scripts/p1-prep-now.sh' 2>&1 | head -25"
run "P2 Play Store hazırlık" "bash '$ROOT/scripts/p2-prep-now.sh' 2>&1 | head -40"
run "Keystore secret rehberi" "bash '$ROOT/scripts/play-keystore-secrets-cheatsheet.sh' 2>&1 | head -28"
run "Play Console checklist" "bash '$ROOT/scripts/play-store-checklist.sh' 2>&1 | tail -18"

echo "══════════════════════════════════════════════════════════════════"
if [[ "$fail" -eq 0 ]]; then
  echo "✅ Agent paralel hazırlık tamam"
else
  echo "⚠️  Bazı adımlarda uyarı — yukarıya bakın"
fi
echo ""
echo "Cihaz (sonra):  bash scripts/cihaz-sonra.sh"
echo "Tam non-device: bash scripts/run-non-device-release-prep.sh"
echo "Durum tablosu:  bash scripts/kalan-isler.sh"
