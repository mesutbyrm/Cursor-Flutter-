#!/usr/bin/env bash
# P2 — tüm agent hazırlık betikleri (tek komut).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P2 prep ALL — agent (cihaz sonucu sonra)                         ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

bash "$ROOT/scripts/p2-prep-now.sh"
echo ""
echo "── App access ──"
bash "$ROOT/scripts/print-play-console-app-access.sh"
echo ""
echo "── Foreground service ──"
bash "$ROOT/scripts/print-play-foreground-service-declaration.sh"
echo ""
echo "── Data safety ──"
bash "$ROOT/scripts/print-play-data-safety-summary.sh"
echo ""
echo "── Content rating (IARC) ──"
bash "$ROOT/scripts/print-play-content-rating-summary.sh"
echo ""
echo "── Store listing ──"
bash "$ROOT/scripts/print-play-store-listing.sh" 2>&1 | head -28
echo ""
echo "── CI AAB adımları ──"
bash "$ROOT/scripts/print-ci-aab-steps.sh" 2>&1 | head -22
echo ""
echo "── Keystore secrets ──"
bash "$ROOT/scripts/play-keystore-secrets-cheatsheet.sh" 2>&1 | head -22
echo ""
echo "Tam checklist: bash scripts/play-store-checklist.sh"
echo "Prep indeks:   bash scripts/print-play-console-prep-index.sh"
