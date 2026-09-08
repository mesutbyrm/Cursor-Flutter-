#!/usr/bin/env bash
# Admin panelden jeton ekledikten hemen sonra — doğrulama + Psychic P0 / M7 / M5.
# Jeton henüz yansımadıysa kısa bekleme önerir.
# Kullanım: bash scripts/after-admin-jeton.sh [min_jeton=100]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

MIN="${1:-100}"
apply_acceptance_credential_defaults

echo "=== after-admin-jeton (min=$MIN) ==="
echo "Hesap: $DEFAULT_ACCEPTANCE_USER_EMAIL"
echo ""

if ! bootstrap_user_token; then
  echo "❌ Test hesabı girişi başarısız — docs/TEST_ACCOUNTS.md"
  exit 1
fi

USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")

J=$(user_jeton_balance_from_me "$USER_TOKEN")

if [[ "$J" -lt "$MIN" ]] && acceptance_admin_secrets_configured 2>/dev/null; then
  echo "Admin top-up deneniyor..."
  ensure_test_jeton_minimum "$USER_TOKEN" "$USER_ID" "$USER_EMAIL" 50 after-admin-jeton >/dev/null 2>&1 || true
  J=$(user_jeton_balance_from_me "$USER_TOKEN")
fi

echo "jeton=$J (hedef≥$MIN)"

if [[ "$J" -lt "$MIN" ]]; then
  echo ""
  echo "⏳ Jeton henüz yansımadı veya yetersiz."
  echo "   Admin: https://canlifal.com/admin → $DEFAULT_ACCEPTANCE_USER_EMAIL"
  echo "   Bekle: bash scripts/wait-for-jeton.sh $MIN 3600"
  exit 2
fi

echo ""
echo "✅ Jeton yeterli — Psychic P0 önkoşul"
bash "$ROOT/scripts/psychic-p0-prereqs.sh" || true
echo ""
echo "── M7 probe (opsiyonel) ──"
bash "$ROOT/scripts/m7-on-jeton.sh" || true
echo ""
echo "── M5 preflight (opsiyonel) ──"
bash "$ROOT/scripts/m5-preflight.sh" || true
echo ""
echo "Sonraki: bash scripts/basla.sh"
echo "Doğrulama: bash scripts/p0-ready.sh"
echo "Detay: docs/RELEASE_USER_NEXT_STEPS.md"
