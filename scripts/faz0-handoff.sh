#!/usr/bin/env bash
# FAZ 0 agent → kullanıcı devir teslimi (tarihsel — güncel: kalan-isler).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "ℹ️  Güncel: bash scripts/basla.sh"
echo "    P0 GO: bash scripts/p0-go.sh"
echo "    Rehber: docs/KALAN_ISLER.md"
echo ""

if [[ "${1:-}" == "--verify" ]]; then
  echo "── Tam otomatik doğrulama (faz0-verify) ──"
  bash "$ROOT/scripts/faz0-verify.sh"
  echo ""
fi

bash "$ROOT/scripts/faz0-status.sh"
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Kullanıcı devir teslimi — öncelik: Psychic P0 (2 tel)  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Agent: TAMAM · Jeton ✅ · Host falcı ✅"
echo ""
echo "── Başla ──"
echo "  bash scripts/basla.sh"
echo "  bash scripts/kalan-isler.sh"
echo "  bash scripts/p0-go.sh"
echo ""
