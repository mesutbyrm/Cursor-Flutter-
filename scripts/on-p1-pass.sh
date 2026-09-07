#!/usr/bin/env bash
# P1 PASS sonrası — sonuç kaydı + RELEASE adayı özeti.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== P1 PASS — RELEASE adayı ==="
echo ""

bash "$ROOT/scripts/record-user-test-result.sh" p1 PASS "${1:-}"

echo ""
echo "── Özet ──"
echo "  Psychic P0: PASS (kayıtlı olmalı)"
echo "  P1 platform: PASS"
echo ""
echo "Agent'a bildirin: P0 PASS + P1 PASS — RELEASE READY adayı"
echo ""
echo "Sonraki: bash scripts/on-release-ready-candidate.sh"
echo "Detay: docs/P2_PLAY_STORE_START.md"
