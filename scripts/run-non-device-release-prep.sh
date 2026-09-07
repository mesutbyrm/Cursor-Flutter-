#!/usr/bin/env bash
# Cihaz testi olmadan release hazırlığı — tek komut (API + unit + durum).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Non-device release prep (cihaz testi sonra)                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

fail=0

run_step() {
  local title="$1" cmd="$2"
  echo "══════════════════════════════════════════════════════════════════"
  echo "── $title ──"
  if eval "$cmd"; then
    echo ""
  else
    echo "⚠️  $title — uyarı (devam)"
    fail=$((fail + 1))
    echo ""
  fi
}

run_step "P0 canlı durum" "bash '$ROOT/scripts/print-p0-live-status.sh'"
run_step "Falcı doğrula (idempotent)" "bash '$ROOT/scripts/open-approved-teller.sh' 2>&1 | tail -6"
run_step "API otomasyon özeti" "bash '$ROOT/scripts/run-api-automation-summary.sh'"
run_step "API release gate (madde 3–8)" "bash '$ROOT/scripts/acceptance-tests/api-release-gate.sh' 2>&1 | tail -12"
run_step "Psychic Flutter unit" "bash '$ROOT/scripts/run-psychic-unit-tests.sh'"

run_step "P2 prep ALL" "bash '$ROOT/scripts/p2-prep-all.sh' 2>&1 | tail -28"

if [[ "$fail" -eq 0 ]]; then
  echo "✅ Cihaz dışı hazırlık tamam — Psychic P0/P1 testi sizde (sonra)"
else
  echo "⚠️  Bazı adımlarda uyarı — detay yukarıda"
fi
echo ""
echo "Agent (şimdi): bash scripts/devam-et.sh"
echo "P2 tam prep:   bash scripts/p2-prep-all.sh"
echo "Cihaz (sonra): bash scripts/basla.sh"
echo "Durum:         bash scripts/kalan-isler.sh"
