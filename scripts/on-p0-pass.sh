#!/usr/bin/env bash
# Psychic P0 PASS sonrası — sonuç kaydı + P1 checklist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Psychic P0 PASS — sonraki adımlar ==="
echo ""

bash "$ROOT/scripts/record-user-test-result.sh" p0 PASS "${1:-}"

echo ""
echo "── P1 platform checklist (2 cihaz) ──"
bash "$ROOT/scripts/p1-platform-checklist.sh"

echo ""
echo "P1 bitince:"
echo "  bash scripts/p1-go.sh"
echo "  bash scripts/record-user-test-result.sh p1 PASS"
echo "  veya: bash scripts/on-p1-pass.sh"
echo ""
echo "Detay: docs/P1_DEVICE_START.md · docs/RELEASE_USER_NEXT_STEPS.md"
