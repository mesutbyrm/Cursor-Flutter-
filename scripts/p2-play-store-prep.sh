#!/usr/bin/env bash
# P2 Play Store hazırlık — cihaz testi sonrası backlog özeti.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P2 Play Store hazırlık (${VERSION})                              ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Önkoşul (cihaz — kullanıcı sonra):"
echo "  [ ] Psychic P0 PASS"
echo "  [ ] P1 platform PASS"
echo ""
echo "── Agent / CI (hazır) ──"
echo "  ✅ Release gate CI FINAL PASS"
echo "  ✅ Mobil kod + otomatik testler CI'da"
echo ""
echo "── Agent prep (şimdi) ──"
echo "  bash scripts/p2-prep-all.sh"
echo "  bash scripts/play-store-checklist.sh"
echo ""
echo "── P2 adımlar (P0+P1 PASS sonrası yükleme) ──"
echo "  bash scripts/on-release-ready-candidate.sh"
echo "  bash scripts/build-play-aab.sh    # keystore secret gerekir"
echo ""
echo "Rehberler:"
echo "  docs/P2_PLAY_STORE_START.md"
echo "  docs/PLAY_STORE_PRODUCTION_ACCESS.md"
echo "  docs/STAGE8_FINAL_ACCEPTANCE_REPORT.md"
echo ""
bash "$ROOT/scripts/release-remaining-status.sh" 2>&1 | grep -E 'P2 ·|RELEASE READY' || true
