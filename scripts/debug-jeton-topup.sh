#!/usr/bin/env bash
# Jeton top-up tanılama — ACCEPTANCE_ADMIN_* gerekli.
# Kullanım: JETON_TOPUP_DEBUG=1 bash scripts/debug-jeton-topup.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

export JETON_TOPUP_DEBUG=1
apply_acceptance_credential_defaults

echo "=== Jeton top-up debug ==="
echo "Base: $BASE"
echo ""

if ! acceptance_admin_secrets_configured; then
  echo "❌ ACCEPTANCE_ADMIN_EMAIL/USERNAME + PASSWORD yok"
  echo "   docs/M5_M7_JETON_BLOCKER.md"
  exit 2
fi

echo "Admin secret: yapılandırılmış"
if login_as_admin; then
  echo "✅ Admin JWT alındı (${#ADMIN_TOKEN} chars)"
else
  echo "❌ Admin girişi başarısız (email ve username denendi)"
  exit 3
fi

if ! bootstrap_user_token; then
  echo "❌ Test kullanıcı girişi başarısız"
  exit 4
fi

USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")

JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
echo "Test: $USER_EMAIL id=$USER_ID jeton=$JETON"
echo ""

if [[ -z "$USER_ID" ]]; then
  echo "❌ user id boş"
  exit 5
fi

admin_user_code=$(http_code "$BASE/api/admin/users/$USER_ID" -H "Authorization: Bearer $ADMIN_TOKEN")
echo "GET /api/admin/users/$USER_ID → HTTP $admin_user_code"
echo ""

echo "── top_up_test_jeton (hedef=50) ──"
if result=$(top_up_test_jeton "$USER_ID" 50 "debug-jeton-topup" 2>&1); then
  echo "✅ top-up OK → $result"
  JETON_AFTER=$(user_jeton_balance_from_me "$USER_TOKEN")
  echo "Yeni jeton: $JETON_AFTER"
  exit 0
fi

echo "❌ top-up başarısız (yukarıdaki [jeton-topup] satırlarına bakın)"
exit 6
