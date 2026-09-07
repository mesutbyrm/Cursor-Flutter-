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
echo "── Keystore secrets ──"
bash "$ROOT/scripts/play-keystore-secrets-cheatsheet.sh" 2>&1 | head -22
echo ""
echo "Tam checklist: bash scripts/play-store-checklist.sh"
