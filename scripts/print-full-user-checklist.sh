#!/usr/bin/env bash
# P0 + P1 yazdırılabilir birleşik checklist.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo ""
bash "$ROOT/scripts/psychic-p0-checklist.sh"
echo ""
echo "══════════════════════════════════════════════════════════════════"
echo ""
bash "$ROOT/scripts/p1-platform-checklist.sh"
echo ""
echo "Sonuç kaydı:"
echo "  bash scripts/on-p0-pass.sh"
echo "  bash scripts/on-p1-pass.sh"
