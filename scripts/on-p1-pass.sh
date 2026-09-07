#!/usr/bin/env bash
# P1 PASS sonrası — sonuç kaydı + RELEASE adayı özeti.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

echo "=== P1 PASS — RELEASE adayı ==="
echo ""

if ! device_test_log_has_pass "Psychic P0" "$LOG"; then
  echo "⚠️  Psychic P0 PASS kaydı yok — yine de P1 kaydediliyor"
  echo "   Öneri: önce bash scripts/on-p0-pass.sh"
  echo ""
fi

bash "$ROOT/scripts/record-user-test-result.sh" p1 PASS "${1:-}"

echo ""
echo "── Özet ──"
echo "  Psychic P0: PASS (kayıtlı olmalı)"
echo "  P1 platform: PASS"
echo ""
echo "Agent'a bildirin: P0 PASS + P1 PASS — RELEASE READY adayı"
echo ""
echo "Sonraki: bash scripts/on-release-ready-candidate.sh"
echo "Play Store: bash scripts/p2-go.sh · bash scripts/print-ci-aab-steps.sh"
echo "Engeller: bash scripts/print-release-blockers.sh"
