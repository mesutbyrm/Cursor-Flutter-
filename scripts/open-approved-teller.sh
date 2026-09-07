#!/usr/bin/env bash
# Host hesabını onaylı falcı yap — başvuru + admin onayı (ACCEPTANCE_ADMIN_* varsa otomatik).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults

HOST_EMAIL="${ACCEPTANCE_HOST_EMAIL:-$DEFAULT_ACCEPTANCE_HOST_EMAIL}"
HOST_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-$DEFAULT_ACCEPTANCE_HOST_PASSWORD}"
DISPLAY_NAME="${TELLER_DISPLAY_NAME:-Cursor Host Test}"

echo "=== Onaylı falcı aç (host → teller) ==="
echo "Hesap: $HOST_EMAIL"
echo ""

if ! bootstrap_host_token; then
  echo "❌ Host girişi başarısız"
  exit 1
fi

profile=$(curl_json "$BASE/api/fortune-tellers/my-profile" -H "Authorization: Bearer $HOST_TOKEN" 2>/dev/null || echo "{}")
read -r teller_id app_status display <<<"$(printf '%s' "$profile" | python3 -c "
import json,sys
d=json.load(sys.stdin)
if not isinstance(d, dict):
    sys.exit(0)
print(d.get('id') or '', d.get('applicationStatus') or '', d.get('displayName') or '')
" 2>/dev/null || echo '  ')"

if [[ -z "$teller_id" ]]; then
  echo "── Falcı başvurusu gönderiliyor ──"
  apply_body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/fortune-tellers/apply" \
    -H "Authorization: Bearer $HOST_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(DISPLAY_NAME="$DISPLAY_NAME" python3 -c 'import json,os; print(json.dumps({
      "displayName": os.environ["DISPLAY_NAME"],
      "bio": "Acceptance QA — Psychic P0 test falcısı",
      "specialties": ["tarot"]
    }))')")
  apply_code=$(printf '%s' "$apply_body" | tail -1 | sed 's/HTTP://')
  apply_json=$(printf '%s' "$apply_body" | sed '$d')
  if [[ "$apply_code" != "200" && "$apply_code" != "201" ]]; then
    echo "❌ Başvuru HTTP $apply_code"
    printf '%s\n' "$apply_json" | head -c 400
    exit 1
  fi
  read -r teller_id app_status display <<<"$(printf '%s' "$apply_json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
t=d.get('teller') or d
print(t.get('id') or '', t.get('applicationStatus') or 'pending', t.get('displayName') or '')
" 2>/dev/null || echo ' pending ')"
  echo "✅ Başvuru oluşturuldu — tellerId=$teller_id status=$app_status"
else
  echo "✅ Mevcut profil — tellerId=$teller_id status=${app_status:-?} name=${display:-?}"
fi

if [[ "$app_status" == "approved" ]]; then
  echo ""
  echo "✅ Zaten onaylı — probe:"
  bash "$ROOT/scripts/probe-psychic-teller.sh"
  exit 0
fi

echo ""
echo "── Admin onayı ──"
if acceptance_admin_secrets_configured; then
  approved=$(try_approve_host_teller "$HOST_TOKEN" || true)
  if [[ -n "$approved" ]]; then
    sleep 1
    profile=$(curl_json "$BASE/api/fortune-tellers/my-profile" -H "Authorization: Bearer $HOST_TOKEN")
    app_status=$(printf '%s' "$profile" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('applicationStatus',''))" 2>/dev/null || echo "")
    if [[ "$app_status" == "approved" ]]; then
      echo "✅ Admin API onayı OK — tellerId=$approved"
      echo ""
      bash "$ROOT/scripts/probe-psychic-teller.sh"
      exit 0
    fi
    echo "⚠️  Admin onay çağrısı yapıldı ama status=$app_status"
  else
    echo "⚠️  Admin onay endpoint başarısız"
  fi
else
  echo "⏭️  ACCEPTANCE_ADMIN_* yok — admin panelden onay gerekir"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Admin panel — manuel onay (1 dakika)                             ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "1. https://canlifal.com/admin"
echo "2. Canlı falcılar / Falcı doğrulama (teller verification)"
echo "3. Bekleyen başvuru: «${display:-Cursor Host Test}»"
echo "   tellerId: $teller_id"
echo "   userId:   cmsyoxo48006emo085hxfy9l7"
echo "   e-posta:  $HOST_EMAIL"
echo "4. Onayla (Approve)"
echo ""
echo "Sonra:"
echo "  bash scripts/probe-psychic-teller.sh"
echo "  bash scripts/open-approved-teller.sh   # tekrar kontrol"
echo ""
echo "CI otomasyonu için GitHub secret:"
echo "  ACCEPTANCE_TELLER_EMAIL=$HOST_EMAIL"
echo "  ACCEPTANCE_TELLER_PASSWORD=<host şifresi>"
