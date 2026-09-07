#!/usr/bin/env bash
# FAZ 0 agent → kullanıcı devir teslimi (tarihsel — güncel: kalan-isler).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "ℹ️  Güncel kalan işler: bash scripts/kalan-isler.sh"
echo "    P0 GO: bash scripts/p0-go.sh"
echo "    Rehber: docs/RELEASE_USER_NEXT_STEPS.md"
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
echo "  bash scripts/kalan-isler.sh"
echo "  bash scripts/p0-go.sh"
echo "  bash scripts/user-handoff.sh"
echo ""
