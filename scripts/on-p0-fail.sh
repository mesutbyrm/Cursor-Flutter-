#!/usr/bin/env bash
# Psychic P0 FAIL — sonuç kaydı + hotfix yönlendirmesi.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NOTE="${*:-T+5s donma veya A/V sorunu}"

echo "=== Psychic P0 FAIL — hotfix gerekir ==="
echo ""

bash "$ROOT/scripts/record-user-test-result.sh" p0 FAIL "$NOTE"

echo ""
echo "Agent'a ekleyin (mümkünse):"
echo "  - Hangi adım (T+5s, reconnect, vb.)"
echo "  - logcat veya ekran kaydı"
echo ""
echo "RELEASE READY: NO — hotfix sonrası tekrar P0"
