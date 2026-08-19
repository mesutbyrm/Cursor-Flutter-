#!/usr/bin/env bash
# FAZ 12 — otomatik kapılar (cihaz E2E hariç).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT="$ROOT/docs/PHASE_12_AUTOMATED_REPORT.md"
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")
PASS=0
FAIL=0

run_gate() {
  local name="$1"
  shift
  echo ""
  echo "── $name ──"
  if "$@"; then
    echo "✅ $name"
    PASS=$((PASS + 1))
  else
    echo "❌ $name"
    FAIL=$((FAIL + 1))
  fi
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  FAZ 12 Otomatik kapılar — $UTC"
echo "╚══════════════════════════════════════════════════════════╝"

run_gate "FAZ0 verify" bash "$ROOT/scripts/faz0-verify.sh"
run_gate "Faz unit testleri" bash "$ROOT/scripts/run-phase-tests.sh"
run_gate "FAZ11 security" bash "$ROOT/scripts/faz11-security-scan.sh"

{
  echo "# FAZ 12 — Otomatik rapor"
  echo ""
  echo "**Tarih:** $UTC"
  echo "**PASS:** $PASS | **FAIL:** $FAIL"
  echo ""
  echo "Manuel: Android 25 senaryo — \`docs/PHASE_12_ACCEPTANCE.md\`"
} >"$REPORT"

echo ""
echo "Sonuç: PASS=$PASS FAIL=$FAIL"
echo "Rapor: docs/PHASE_12_AUTOMATED_REPORT.md"
[[ "$FAIL" -eq 0 ]]
