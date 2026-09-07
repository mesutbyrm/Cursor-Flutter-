#!/usr/bin/env bash
# FAZ 0 agent → kullanıcı devir teslimi (tarihsel — güncel: user-test-start).
# Güncel: bash scripts/user-test-start.sh · docs/RELEASE_USER_NEXT_STEPS.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "ℹ️  Güncel release: bash scripts/user-test-start.sh"
echo "    Tam rehber: docs/RELEASE_USER_NEXT_STEPS.md"
echo ""
if [[ "${1:-}" == "--verify" ]]; then
  echo "── Tam otomatik doğrulama (faz0-verify) ──"
  bash "$ROOT/scripts/faz0-verify.sh"
  echo ""
fi

bash "$ROOT/scripts/faz0-status.sh"
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Kullanıcı devir teslimi — güncel öncelik: Psychic P0   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "Agent: TAMAM · Jeton P0-j: ✅ (~100k) · Falcı: onaylı hesap gerekir"
echo ""
echo "── Tek giriş ──"
echo "  bash scripts/user-test-start.sh"
echo "  bash scripts/user-handoff.sh"
echo ""
echo "── API otomasyon (tamam) ──"
echo "  bash scripts/run-api-automation-summary.sh"
echo ""
echo "── M5 cihaz (P0/P1 sonrası) ──"
echo "  docs/M5_DEVICE_TEST_CHECKLIST.md"
echo ""
