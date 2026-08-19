#!/usr/bin/env bash
# FAZ 0 sonraki adımlar — durum, cheatsheet, jeton probe; jeton varsa M7+M5-preflight.
# Kullanım: bash scripts/faz0-next.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  FAZ 0 — sonraki adımlar                                 ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

bash "$ROOT/scripts/faz0-status.sh"
echo ""
bash "$ROOT/scripts/admin-jeton-cheatsheet.sh"
echo ""

# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"
apply_acceptance_credential_defaults

JETON=0
if bootstrap_user_token 2>/dev/null; then
  JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
fi

if [[ "$JETON" -ge 10 ]]; then
  echo "✅ jeton=$JETON — M7 + m5-preflight başlıyor"
  bash "$ROOT/scripts/m7-on-jeton.sh"
  echo ""
  bash "$ROOT/scripts/m5-preflight.sh" || true
  echo ""
  echo "Sonraki: docs/M5_DEVICE_TEST_CHECKLIST.md"
  exit 0
fi

echo "── Jeton kazanım probe ──"
bash "$ROOT/scripts/probe-jeton-earn.sh" || true
echo ""
echo "Jeton < 10 — admin panel veya ACCEPTANCE_ADMIN_* gerekli."
echo "Jeton eklenince: bash scripts/wait-for-jeton.sh 10 3600"
exit 1
