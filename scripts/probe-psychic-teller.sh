#!/usr/bin/env bash
# Psychic P0 — falcı/host hesabının üretim falcı listesinde olup olmadığını kontrol eder.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=acceptance-tests/defaults.sh
source "$ROOT/scripts/acceptance-tests/defaults.sh"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

require_cmd curl python3

apply_acceptance_credential_defaults

HOST_EMAIL="${HOST_EMAIL:-$DEFAULT_ACCEPTANCE_HOST_EMAIL}"
HOST_PASSWORD="${HOST_PASSWORD:-$DEFAULT_ACCEPTANCE_HOST_PASSWORD}"

echo "=== Psychic falcı probe ==="
echo ""

check_teller_token() {
  local label="$1" email="$2" token="$3"
  local me_body user_id username profile_body tellers_body result listed profile_id app_status list_count matched_id

  me_body=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $token")
  read -r user_id username <<<"$(printf '%s' "$me_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
uid=str(d.get('id') or d.get('user',{}).get('id') or '').strip()
uname=str(d.get('username') or d.get('user',{}).get('username') or '').strip()
print(uid, uname)
" 2>/dev/null || echo ' ')"

  profile_body=$(curl_json "$BASE/api/fortune-tellers/my-profile" -H "Authorization: Bearer $token" 2>/dev/null || echo "{}")
  tellers_body=$(curl_json "$BASE/api/fortune-tellers")

  result=$(TELLER_EMAIL="$email" TELLER_USER_ID="$user_id" TELLER_USERNAME="$username" \
    PROFILE_JSON="$profile_body" TELLERS_JSON="$tellers_body" python3 -c "
import json, os

email = os.environ.get('TELLER_EMAIL', '')
user_id = os.environ.get('TELLER_USER_ID', '')
username = os.environ.get('TELLER_USERNAME', '')
profile = json.loads(os.environ.get('PROFILE_JSON') or '{}')
raw = os.environ.get('TELLERS_JSON') or '{}'
try:
    d = json.loads(raw)
except json.JSONDecodeError:
    d = {}
items = d.get('tellers') or d.get('data', {}).get('tellers') or d.get('items') or []

def norm(s):
    return str(s or '').strip().lower()

matched = []
for t in items:
    if not isinstance(t, dict):
        continue
    tu = str(t.get('userId') or t.get('user', {}).get('id') or '').strip()
    te = norm(t.get('email') or t.get('user', {}).get('email'))
    if user_id and tu == user_id:
        matched.append(t)
    elif email and te == norm(email):
        matched.append(t)

profile_id = str(profile.get('id') or '').strip()
app_status = str(profile.get('applicationStatus') or profile.get('status') or '').strip()
listed = bool(matched)
print(json.dumps({
    'listedInFortuneTellers': listed,
    'listCount': len(items),
    'profileId': profile_id,
    'applicationStatus': app_status,
    'matchedId': (matched[0].get('id') if matched else profile_id) or '',
}, ensure_ascii=False))
")

  listed=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('listedInFortuneTellers'))")
  profile_id=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('profileId',''))")
  app_status=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('applicationStatus',''))")
  list_count=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('listCount',0))")
  matched_id=$(printf '%s' "$result" | python3 -c "import json,sys; print(json.load(sys.stdin).get('matchedId',''))")

  echo "── $label ($email) ──"
  echo "  userId=$user_id username=$username"
  echo "  /fortune-tellers listesi: $list_count falcı"
  if [[ -n "$profile_id" ]]; then
    echo "  my-profile id=$profile_id status=${app_status:-?}"
  else
    echo "  my-profile: yok veya boş"
  fi

  if [[ "$listed" == "True" ]]; then
    echo "✅ Falcı listesinde — Psychic P0 falcı hesabı kullanılabilir (tellerId=$matched_id)"
    return 0
  fi

  echo "⚠️  Falcı listesinde DEĞİL — Psychic seans kabul edilmeyebilir"
  echo "    Çözüm: admin panelden onaylı falcı hesabı veya ACCEPTANCE_TELLER_* secret"
  echo "    docs/TEST_ACCOUNTS.md · docs/PSYCHIC_P0_START.md"
  sample=$(printf '%s' "$tellers_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('tellers') or d.get('data',{}).get('tellers') or d.get('items') or []
names=[]
for t in items[:5]:
    if not isinstance(t, dict): continue
    n=t.get('displayName') or t.get('name') or t.get('username') or '?'
    names.append(str(n))
if names:
    print('    Üretimde örnek falcılar:', ', '.join(names))
" 2>/dev/null || true)
  [[ -n "$sample" ]] && echo "$sample"
  return 2
}

exit_code=0

  if [[ -n "${ACCEPTANCE_TELLER_EMAIL:-}" || -n "${ACCEPTANCE_TELLER_USERNAME:-}" ]]; then
  teller_email="${ACCEPTANCE_TELLER_EMAIL:-}"
  teller_pass="${ACCEPTANCE_TELLER_PASSWORD:-}"
  teller_token=""
  if [[ -n "$teller_email" ]]; then
    resp=$(mobile_login_identifier email "$teller_email" "$teller_pass")
    teller_token=$(extract_token "$resp")
  else
    resp=$(mobile_login_identifier username "${ACCEPTANCE_TELLER_USERNAME}" "$teller_pass")
    teller_token=$(extract_token "$resp")
    teller_email="${ACCEPTANCE_TELLER_USERNAME}"
  fi
  if [[ -z "$teller_token" ]]; then
    echo "❌ ACCEPTANCE_TELLER girişi başarısız"
    exit_code=1
  elif [[ "$teller_email" != "$HOST_EMAIL" ]]; then
    check_teller_token "ACCEPTANCE_TELLER" "$teller_email" "$teller_token" || exit_code=$?
    echo ""
  fi
fi

if bootstrap_host_token; then
  check_teller_token "Host (varsayılan)" "$HOST_EMAIL" "$HOST_TOKEN" || exit_code=$?
else
  echo "❌ Host girişi başarısız ($HOST_EMAIL)"
  exit_code=1
fi

echo ""
if [[ "$exit_code" -eq 0 ]]; then
  echo "Falcı probe: listede — P0 cihaz testine devam edilebilir."
elif [[ "$exit_code" -eq 2 ]]; then
  echo "Falcı probe: uyarı — cihazda seans kabul olmazsa onaylı falcı hesabı deneyin."
  exit 0
else
  echo "Falcı probe: giriş hatası — kimlik bilgilerini kontrol edin."
fi

exit "$exit_code"
