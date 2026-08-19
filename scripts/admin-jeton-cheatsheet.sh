#!/usr/bin/env bash
# Admin panel jeton top-up — hızlı referans (test hesabı).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Admin jeton cheatsheet — M5/M7 test hesabı              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "E-posta:    $DEFAULT_ACCEPTANCE_USER_EMAIL"
echo "Kullanıcı:  ${DEFAULT_ACCEPTANCE_USER_USERNAME:-cursorusr1786235468}"
echo ""

if bootstrap_user_token 2>/dev/null; then
  USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")
  JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
  CREDITS=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('credits', 0))
" 2>/dev/null || echo "?")
  echo "User ID:    $USER_ID"
  echo "Jeton:      $JETON"
  echo "Credits:    $CREDITS"
else
  echo "User ID:    cmsyoxjh80066mo08fo7nv5o6 (dokümante)"
  echo "Giriş:      başarısız — TEST_ACCOUNTS.md"
fi

echo ""
echo "── Admin panel adımları ──"
echo "1. https://canlifal.com admin → Kullanıcılar"
echo "2. $DEFAULT_ACCEPTANCE_USER_EMAIL ara"
echo "3. Jeton ekle: ≥50 (M5+M7+yedek)"
echo ""
echo "── Doğrulama ──"
echo "bash scripts/probe-jeton-earn.sh"
echo "bash scripts/m7-on-jeton.sh"
echo "bash scripts/m5-ready.sh"
echo ""
echo "── CI secret (opsiyonel) ──"
echo "ACCEPTANCE_ADMIN_EMAIL + ACCEPTANCE_ADMIN_PASSWORD"
echo "docs/M5_M7_JETON_BLOCKER.md"
