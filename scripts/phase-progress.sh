#!/usr/bin/env bash
# Tüm fazların otomatik durum özeti — PHASE_PLAN.md ile hizalı.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Canlifal Faz İlerlemesi — $UTC"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

bash "$ROOT/scripts/faz0-status.sh" 2>/dev/null | tail -20 || true

echo ""
echo "── Faz test raporu ──"
if [[ -f "$ROOT/docs/PHASE_TEST_REPORT.md" ]]; then
  grep -E "^\| [0-9]|^## Detay" -A20 "$ROOT/docs/PHASE_TEST_REPORT.md" | head -25
else
  echo "  Henüz yok — bash scripts/run-phase-tests.sh"
fi

echo ""
echo "── Faz durum dosyaları ──"
for f in "$ROOT"/docs/FAZ*_STATUS.md "$ROOT"/docs/FAZ*_PARITY.md "$ROOT"/docs/PHASE_MASTER_TRACKER.md; do
  [[ -f "$f" ]] && echo "  ✅ $(basename "$f")" || true
done

echo ""
echo "── Manuel blokerler (tüm fazlar) ──"
echo "  ⛔ FAZ0 M5/M7: jeton ≥10 + Android cihaz"
echo "  ⛔ FAZ12: 25 senaryo gerçek cihaz"
echo "  ⛔ FAZ13: signing secrets (CI)"
