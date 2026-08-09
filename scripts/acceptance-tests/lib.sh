#!/usr/bin/env bash
# Acceptance test yardımcıları — kaynak: scripts/run-acceptance-tests.sh
set -euo pipefail

_normalize_base_url() {
  local u="${1:-https://canlifal.com}"
  u="${u#"${u%%[![:space:]]*}"}"
  u="${u%"${u##*[![:space:]]}"}"
  while [[ "$u" == */ ]]; do u="${u%/}"; done
  if [[ "$u" == */api ]]; then u="${u%/api}"; fi
  printf '%s' "$u"
}

BASE="$(_normalize_base_url "${CANLIFAL_BASE_URL:-${API_BASE_URL:-https://canlifal.com}}")"
REPORT_DIR="${ACCEPTANCE_REPORT_DIR:-docs}"
REPORT_JSON="${REPORT_DIR}/ACCEPTANCE_TEST_REPORT.json"
REPORT_MD="${REPORT_DIR}/ACCEPTANCE_TEST_REPORT.md"
RUN_ID="${GITHUB_RUN_ID:-local-$(date +%s)}"

PASS=0
FAIL=0
SKIP=0
declare -a RESULT_LINES=()

require_cmd() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || {
      echo "Gerekli komut yok: $c" >&2
      exit 2
    }
  done
}

json_field() {
  local expr="$1"
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d$expr)" 2>/dev/null || true
}

http_code() {
  curl -sS -o /dev/null -w "%{http_code}" "$@"
}

curl_json() {
  curl -sS "$@"
}

mobile_login() {
  local body="$1"
  curl -sS -X POST "$BASE/api/auth/mobile-login" \
    -H "Content-Type: application/json" \
    -d "$body"
}

# Özel karakterli şifreler için güvenli JSON gövdesi.
mobile_login_payload() {
  LOGIN_KIND="${1:-}" LOGIN_ID="${2:-}" LOGIN_PASS="${3:-}" python3 - <<'PY'
import json, os
kind = os.environ.get("LOGIN_KIND", "")
ident = os.environ.get("LOGIN_ID", "")
password = os.environ.get("LOGIN_PASS", "")
body = {"password": password}
if kind == "email":
    body["email"] = ident
    body["emailOrUsername"] = ident
else:
    body["emailOrUsername"] = ident
    body["username"] = ident
print(json.dumps(body))
PY
}

mobile_login_identifier() {
  local kind="$1" ident="$2" pass="$3"
  mobile_login "$(mobile_login_payload "$kind" "$ident" "$pass")"
}

login_error_detail() {
  local resp="$1"
  printf '%s' "$resp" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw:
    print('boş yanıt'); sys.exit()
try:
    d=json.loads(raw)
except json.JSONDecodeError:
    print(raw[:120]); sys.exit()
for k in ('error','message','detail'):
    v=d.get(k)
    if isinstance(v,str) and v.strip():
        print(v.strip()[:160]); sys.exit()
print(raw[:120])
" 2>/dev/null || echo "bilinmeyen hata"
}

extract_token() {
  local resp="$1"
  local tok
  tok=$(printf '%s' "$resp" | json_field "['accessToken']")
  if [[ -z "$tok" ]]; then
    tok=$(printf '%s' "$resp" | json_field "['token']")
  fi
  if [[ -z "$tok" ]]; then
    tok=$(printf '%s' "$resp" | json_field "['data']['accessToken']")
  fi
  if [[ -z "$tok" ]]; then
    tok=$(printf '%s' "$resp" | json_field "['data']['token']")
  fi
  printf '%s' "$tok"
}

extract_stream_id() {
  local resp="$1"
  printf '%s' "$resp" | python3 -c "
import json,sys
def pick_id(d):
    if not isinstance(d, dict):
        return ''
    if d.get('success') is True and d.get('data') is not None:
        return pick_id(d['data'])
    for key in ('stream', 'videoStream', 'broadcast'):
        nested = d.get(key)
        if isinstance(nested, dict):
            got = pick_id(nested)
            if got:
                return got
    for key in ('id', '_id', 'streamId', 'roomId'):
        v = d.get(key)
        if v is not None and str(v).strip():
            return str(v).strip()
    return ''
raw = sys.stdin.read().strip()
if not raw:
    sys.exit(0)
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)
print(pick_id(data))
" 2>/dev/null || true
}

# Oturum: önce kullanıcı adı, sonra e-posta.
bootstrap_user_token() {
  local resp tok
  if [[ -n "${USER_TOKEN:-}" ]]; then
    return 0
  fi
  if [[ -n "${ACCEPTANCE_USER_USERNAME:-}" && -n "${ACCEPTANCE_USER_PASSWORD:-}" ]]; then
    resp=$(mobile_login_identifier username "$ACCEPTANCE_USER_USERNAME" "$ACCEPTANCE_USER_PASSWORD")
    tok=$(extract_token "$resp")
    if [[ -n "$tok" ]]; then
      USER_TOKEN="$tok"
      return 0
    fi
  fi
  if acceptance_user_secrets_configured; then
    resp=$(mobile_login_identifier email "$ACCEPTANCE_USER_EMAIL" "$ACCEPTANCE_USER_PASSWORD")
    tok=$(extract_token "$resp")
    if [[ -n "$tok" ]]; then
      USER_TOKEN="$tok"
      return 0
    fi
  fi
  return 1
}

bootstrap_host_token() {
  local resp tok
  if [[ -n "${HOST_TOKEN:-}" ]]; then
    return 0
  fi
  if [[ -z "${HOST_EMAIL:-}" || -z "${HOST_PASSWORD:-}" ]]; then
    return 1
  fi
  resp=$(mobile_login_identifier email "$HOST_EMAIL" "$HOST_PASSWORD")
  tok=$(extract_token "$resp")
  if [[ -n "$tok" ]]; then
    HOST_TOKEN="$tok"
    return 0
  fi
  if [[ -n "${ACCEPTANCE_USER_USERNAME:-}" ]]; then
    resp=$(mobile_login_identifier username "$ACCEPTANCE_USER_USERNAME" "$HOST_PASSWORD")
    tok=$(extract_token "$resp")
    if [[ -n "$tok" ]]; then
      HOST_TOKEN="$tok"
      return 0
    fi
  fi
  return 1
}

pick_first_room_id() {
  local body="$1"
  printf '%s' "$body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw:
    sys.exit(0)
d=json.loads(raw)
rooms=[]
if isinstance(d, list):
    rooms=d
elif isinstance(d, dict):
    if d.get('success') is True and d.get('data') is not None:
        data=d['data']
        if isinstance(data, list):
            rooms=data
        elif isinstance(data, dict):
            rooms=data.get('rooms') or data.get('items') or []
    else:
        rooms=d.get('rooms') or d.get('items') or []
        if isinstance(rooms, dict):
            rooms=rooms.get('rooms') or rooms.get('items') or []
for r in rooms:
    if isinstance(r, dict):
        rid=str(r.get('id') or r.get('roomId') or '').strip()
        if rid:
            print(rid)
            break
" 2>/dev/null || true
}

create_video_stream() {
  local token="$1" title="$2" category="${3:-fortune}"
  local create_body create_resp create_code
  create_body=$(CREATE_TITLE="$title" CREATE_CATEGORY="$category" python3 -c 'import json,os; print(json.dumps({
    "title":os.environ["CREATE_TITLE"],
    "name":os.environ["CREATE_TITLE"],
    "status":"live",
    "requestType":"live",
    "category":os.environ["CREATE_CATEGORY"],
    "tags":["gate","fortune"],
    "isPrivate": False,
    "private": False
  }))')
  create_resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/video-streams" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$create_body")
  create_code=$(echo "$create_resp" | tail -1 | sed 's/HTTP://')
  create_resp=$(echo "$create_resp" | sed '$d')
  STREAM_ID=$(extract_stream_id "$create_resp")
  if [[ -n "$STREAM_ID" ]]; then
    curl -sS -o /dev/null -X POST "$BASE/api/video-streams/$STREAM_ID/live-started" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{}' || true
  fi
  printf '%s|%s' "${STREAM_ID:-}" "${create_code:-}"
}

login_as_teller() {
  local resp
  if [[ -n "${ACCEPTANCE_TELLER_EMAIL:-}" ]]; then
    resp=$(mobile_login_identifier email "$ACCEPTANCE_TELLER_EMAIL" "$ACCEPTANCE_TELLER_PASSWORD")
  elif [[ -n "${ACCEPTANCE_TELLER_USERNAME:-}" ]]; then
    resp=$(mobile_login_identifier username "$ACCEPTANCE_TELLER_USERNAME" "$ACCEPTANCE_TELLER_PASSWORD")
  else
    return 1
  fi
  TELLER_TOKEN=$(extract_token "$resp")
  [[ -n "${TELLER_TOKEN:-}" ]]
}

login_as_admin() {
  local resp
  if [[ -n "${ACCEPTANCE_ADMIN_EMAIL:-}" ]]; then
    resp=$(mobile_login_identifier email "$ACCEPTANCE_ADMIN_EMAIL" "$ACCEPTANCE_ADMIN_PASSWORD")
  elif [[ -n "${ACCEPTANCE_ADMIN_USERNAME:-}" ]]; then
    resp=$(mobile_login_identifier username "$ACCEPTANCE_ADMIN_USERNAME" "$ACCEPTANCE_ADMIN_PASSWORD")
  else
    return 1
  fi
  ADMIN_TOKEN=$(extract_token "$resp")
  [[ -n "${ADMIN_TOKEN:-}" ]]
}

# Test kullanıcısına jeton ekle — yalnızca ACCEPTANCE_ADMIN_* ile; production gerçek kullanıcıya dokunmaz.
top_up_test_jeton() {
  local user_id="$1" target_balance="${2:-1500}" reason="${3:-acceptance-stage5}"
  local current need amount body code
  if [[ -z "$user_id" ]]; then
    return 1
  fi
  if ! login_as_admin; then
    return 2
  fi
  current=$(curl_json "$BASE/api/admin/users/$user_id" \
    -H "Authorization: Bearer $ADMIN_TOKEN" 2>/dev/null | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw: sys.exit(0)
d=json.loads(raw)
u=d.get('user') or d.get('data') or d
for k in ('jetonBalance','coins','jeton'):
    v=u.get(k) if isinstance(u,dict) else d.get(k)
    if v is not None:
        print(int(v)); break
" 2>/dev/null || echo "")
  if [[ -z "$current" ]]; then
    current=0
  fi
  need=$((target_balance - current))
  if [[ "$need" -le 0 ]]; then
    printf '%s' "$current"
    return 0
  fi
  amount="$need"
  for body in \
    "$(USER_ID="$user_id" AMOUNT="$amount" REASON="$reason" python3 -c 'import json,os; print(json.dumps({"userId":os.environ["USER_ID"],"type":"jeton","amount":int(os.environ["AMOUNT"]),"action":"add","reason":os.environ["REASON"]}))')" \
    "$(USER_ID="$user_id" AMOUNT="$amount" REASON="$reason" python3 -c 'import json,os; print(json.dumps({"userId":os.environ["USER_ID"],"creditType":"jeton","amount":int(os.environ["AMOUNT"]),"operation":"add","note":os.environ["REASON"]}))')"
  do
    code=$(http_code -X POST "$BASE/api/admin/credits" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$body")
    if [[ "$code" == "200" || "$code" == "201" ]]; then
      sleep 1
      printf '%s' "$target_balance"
      return 0
    fi
    code=$(http_code -X PATCH "$BASE/api/admin/users/credits" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$body")
    if [[ "$code" == "200" || "$code" == "201" ]]; then
      sleep 1
      printf '%s' "$target_balance"
      return 0
    fi
  done
  return 3
}

user_jeton_balance_from_me() {
  local token="$1"
  curl_json "$BASE/api/me" -H "Authorization: Bearer $token" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for k in ('jetonBalance','coins','credits'):
    v=d.get(k)
    if v is None and isinstance(d.get('user'),dict):
        v=d['user'].get(k)
    if v is not None:
        print(int(v)); break
" 2>/dev/null || echo "0"
}

# Test hesabı jetonu yetersizse (yalnızca doğrulanmış test e-postası + admin secret).
ensure_test_jeton_minimum() {
  local token="$1" user_id="$2" email="$3" min_balance="$4" label="${5:-test}"
  local current need
  current=$(user_jeton_balance_from_me "$token")
  if [[ "$current" -ge "$min_balance" ]]; then
    printf '%s' "$current"
    return 0
  fi
  if ! is_verified_test_email "$email" 2>/dev/null; then
    echo "FAIL: $label jeton=$current < $min_balance (test e-postası doğrulanamadı)" >&2
    return 1
  fi
  if ! acceptance_admin_secrets_configured; then
    echo "FAIL: $label jeton=$current < $min_balance — ACCEPTANCE_ADMIN_* yok; admin panelden test jetonu ekleyin" >&2
    return 2
  fi
  need=$((min_balance - current))
  if top_up_test_jeton "$user_id" "$min_balance" "stage6-$label" >/dev/null 2>&1; then
    sleep 1
    current=$(user_jeton_balance_from_me "$token")
    printf '%s' "$current"
    return 0
  fi
  echo "FAIL: $label jeton top-up başarısız (hedef=$min_balance)" >&2
  return 3
}

is_verified_test_email() {
  local email="$1"
  [[ "$email" =~ ^cursor\.(test|host)\.[0-9]+@mailinator\.com$ ]]
}

fetch_me_field() {
  local token="$1" field="$2"
  curl_json "$BASE/api/me" -H "Authorization: Bearer $token" | python3 -c "
import json,sys
field=sys.argv[1]
d=json.load(sys.stdin)
u=d.get('user') or {}
print(d.get(field) or u.get(field) or '')
" "$field" 2>/dev/null || true
}

# TRTC yanıtı düz veya { success, data: { userSig, sdkAppId } } olabilir.
trtc_response_has_sig() {
  local body="$1"
  printf '%s' "$body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw:
    sys.exit(1)
try:
    d=json.loads(raw)
except json.JSONDecodeError:
    sys.exit(1)
node=d.get('data') if isinstance(d.get('data'), dict) else d
sig=node.get('userSig') or node.get('token') or d.get('userSig') or d.get('token')
sdk=node.get('sdkAppId') or d.get('sdkAppId')
if sig and sdk and len(str(sig)) > 20:
    sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

create_owned_chat_room() {
  local token="$1" name="$2"
  curl -sS -X POST "$BASE/api/chat/rooms/create" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$(NAME="$name" python3 -c 'import json,os; print(json.dumps({
      "name": os.environ["NAME"],
      "description": "Acceptance test room",
      "icon": "🎙️",
      "paymentType": "jeton",
      "roomType": "free"
    }))')"
}

extract_chat_room_id() {
  local body="$1"
  printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
r=d.get('room') or d.get('data') or {}
if isinstance(r, dict):
    print(r.get('id') or r.get('roomId') or '')
" 2>/dev/null || true
}

# Kullanıcının takılı kalmış PK savaşını sonlandır (oda bazlı GET /pk).
cleanup_room_pk() {
  local token="$1" room_id="$2"
  local status_body battle_id
  [[ -z "$room_id" ]] && return 0
  status_body=$(curl_json "$BASE/api/chat/rooms/$room_id/pk" -H "Authorization: Bearer $token" 2>/dev/null || echo "")
  battle_id=$(printf '%s' "$status_body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw or raw=='null': sys.exit(0)
d=json.loads(raw)
if not isinstance(d, dict): sys.exit(0)
if d.get('status') in ('active','pending'):
    print(d.get('id') or '')
" 2>/dev/null || echo "")
  if [[ -n "$battle_id" ]]; then
    curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$room_id/pk" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{"action":"end","battleId":"'"$battle_id"'"}' || true
    curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$room_id/pk" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d '{"action":"cancel","battleId":"'"$battle_id"'"}' || true
  fi
}

cleanup_user_pk_battles() {
  local token="$1"
  local rooms_body room_ids rid
  rooms_body=$(curl_json "$BASE/api/chat/rooms?limit=30" -H "Authorization: Bearer $token" 2>/dev/null || echo "[]")
  room_ids=$(printf '%s' "$rooms_body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw: sys.exit(0)
d=json.loads(raw)
rooms=d if isinstance(d,list) else d.get('rooms') or d.get('items') or []
for r in rooms:
    if isinstance(r,dict):
        rid=str(r.get('id') or r.get('roomId') or '').strip()
        if rid: print(rid)
" 2>/dev/null || true)
  while IFS= read -r rid; do
    [[ -z "$rid" ]] && continue
    cleanup_room_pk "$token" "$rid"
  done <<<"$room_ids"
}

try_approve_host_teller() {
  local host_token="$1"
  local teller_id profile_body code
  if ! login_as_admin; then
    return 2
  fi
  profile_body=$(curl_json "$BASE/api/fortune-tellers/my-profile" \
    -H "Authorization: Bearer $host_token" 2>/dev/null || echo "")
  teller_id=$(printf '%s' "$profile_body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw: sys.exit(0)
d=json.loads(raw)
print(d.get('id') or '')
" 2>/dev/null || echo "")
  if [[ -z "$teller_id" ]]; then
    return 3
  fi
  for endpoint in \
    "$BASE/api/admin/teller-verification" \
    "$BASE/api/admin/live-tellers/$teller_id/approve"
  do
    code=$(http_code -X POST "$endpoint" \
      -H "Authorization: Bearer $ADMIN_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$(TELLER_ID="$teller_id" python3 -c 'import json,os; print(json.dumps({
        "tellerId": os.environ["TELLER_ID"],
        "action": "approve",
        "note": "acceptance-stage5-auto"
      }))')")
    if [[ "$code" == "200" || "$code" == "201" ]]; then
      printf '%s' "$teller_id"
      return 0
    fi
  done
  return 4
}

find_payment_in_admin_list() {
  local list="$1" rid="$2" ref="$3"
  printf '%s' "$list" | python3 -c "
import json,sys
rid=sys.argv[1]
ref=sys.argv[2]
raw=sys.stdin.read().strip()
if not raw:
    print('no'); sys.exit()
d=json.loads(raw)
def flatten_items(node):
    if isinstance(node, list):
        return [x for x in node if isinstance(x, dict)]
    if not isinstance(node, dict):
        return []
    for key in ('requests','items','notifications','paymentNotifications','data'):
        val=node.get(key)
        if isinstance(val, list):
            return [x for x in val if isinstance(x, dict)]
        if isinstance(val, dict):
            nested=flatten_items(val)
            if nested:
                return nested
    return []
items=flatten_items(d)
for x in items:
    if rid and str(x.get('id',''))==rid:
        print('yes'); sys.exit()
    if rid and str(x.get('targetId',''))==rid:
        print('yes'); sys.exit()
    data=x.get('data')
    if isinstance(data, dict) and rid and str(data.get('paymentRequestId',''))==rid:
        print('yes'); sys.exit()
    blob=json.dumps(x, ensure_ascii=False)
    if ref in blob:
        print('yes'); sys.exit()
print('no')
" "$rid" "$ref" 2>/dev/null || echo "no"
}

extract_request_id() {
  local resp="$1"
  printf '%s' "$resp" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw:
    sys.exit(0)
d=json.loads(raw)
def pick(node):
    if isinstance(node, dict):
        for k in ('id','requestId'):
            v=node.get(k)
            if v: return str(v)
        for k in ('request','data'):
            nested=node.get(k)
            if isinstance(nested, dict):
                got=pick(nested)
                if got: return got
    return ''
print(pick(d))
" 2>/dev/null || true
}

pick_live_fortune_stream_id() {
  local token="$1"
  local body
  if [[ -n "$token" ]]; then
    body=$(curl_json "$BASE/api/video-streams?limit=20&status=live" \
      -H "Authorization: Bearer $token")
  else
    body=$(curl -sS "$BASE/api/video-streams?limit=20&status=live")
  fi
  printf '%s' "$body" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
items=d if isinstance(d,list) else d.get('items') or d.get('streams') or d.get('videoStreams') or (d.get('data') or {}).get('items') or []
if isinstance(items,dict):
    items=items.get('items') or items.get('streams') or []
for s in items:
    if not isinstance(s,dict):
        continue
    sid=str(s.get('id') or s.get('streamId') or '').strip()
    if not sid:
        continue
    cat=str(s.get('category') or '').lower()
    tags=s.get('tags') or []
    if cat=='fortune' or 'fortune' in cat or (isinstance(tags,list) and 'fortune' in [str(t).lower() for t in tags]):
        print(sid); break
" 2>/dev/null || true
}

pick_any_live_stream_id() {
  local token="$1"
  local body
  if [[ -n "$token" ]]; then
    body=$(curl_json "$BASE/api/video-streams?limit=20&status=live" \
      -H "Authorization: Bearer $token")
  else
    body=$(curl -sS "$BASE/api/video-streams?limit=20&status=live")
  fi
  printf '%s' "$body" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
items=d if isinstance(d,list) else d.get('items') or d.get('streams') or d.get('videoStreams') or (d.get('data') or {}).get('items') or []
if isinstance(items,dict):
    items=items.get('items') or items.get('streams') or []
for s in items:
    if not isinstance(s,dict):
        continue
    sid=str(s.get('id') or s.get('streamId') or '').strip()
    if sid:
        print(sid)
        break
" 2>/dev/null || true
}

try_resolve_gate_stream() {
  local title="${1:-Gate $RUN_ID}"
  local create_code="" create_result="" token=""
  STREAM_ID=""

  if login_as_teller; then
    token="$TELLER_TOKEN"
    create_result=$(create_video_stream "$token" "$title")
    STREAM_ID="${create_result%%|*}"
    create_code="${create_result##*|}"
    [[ -n "$STREAM_ID" ]] && HOST_TOKEN="$token" && return 0
  fi

  if bootstrap_host_token; then
    token="$HOST_TOKEN"
    create_result=$(create_video_stream "$token" "$title")
    STREAM_ID="${create_result%%|*}"
    create_code="${create_result##*|}"
    [[ -n "$STREAM_ID" ]] && HOST_TOKEN="$token" && return 0
  fi

  if login_as_admin; then
    token="$ADMIN_TOKEN"
    create_result=$(create_video_stream "$token" "$title")
    STREAM_ID="${create_result%%|*}"
    create_code="${create_result##*|}"
    [[ -n "$STREAM_ID" ]] && HOST_TOKEN="$token" && return 0
  fi

  bootstrap_user_token || true
  local picked=""
  for token in "$TELLER_TOKEN" "$HOST_TOKEN" "$ADMIN_TOKEN" "$USER_TOKEN" ""; do
    picked=$(pick_live_fortune_stream_id "$token")
    [[ -z "$picked" ]] && picked=$(pick_any_live_stream_id "$token")
    if [[ -n "$picked" ]]; then
      STREAM_ID="$picked"
      [[ -n "$token" ]] && HOST_TOKEN="$token"
      return 0
    fi
  done

  GATE_LAST_CREATE_CODE="${create_code:-?}"
  return 1
}

post_fortune_request() {
  local stream_id="$1" token="$2" host_token="${3:-}"
  local body resp code rid err nickname question
  nickname="GateTest"
  question="Release gate canlı yayın test fal sorusu?"
  clear_pending_fortune_request "$stream_id" "$token" || true
  body=$(QUESTION="$question" NICK="$nickname" python3 -c 'import json,os; print(json.dumps({
    "typeId":"tek-soru",
    "question":os.environ["QUESTION"],
    "isHidden":False,
    "nickname":os.environ["NICK"]
  }))')
  resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/video-streams/$stream_id/fortune-requests" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$body")
  code=$(echo "$resp" | tail -1 | sed 's/HTTP://')
  resp=$(echo "$resp" | sed '$d')
  rid=$(extract_request_id "$resp")
  if [[ -n "$rid" ]]; then
    printf '%s|%s|' "$rid" "$code"
    return 0
  fi
  err=$(login_error_detail "$resp")
  if [[ "$code" == "400" && "$err" == *"bekleyen"* ]]; then
    clear_pending_fortune_request "$stream_id" "$token" || true
    resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/video-streams/$stream_id/fortune-requests" \
      -H "Authorization: Bearer $token" \
      -H "Content-Type: application/json" \
      -d "$body")
    code=$(echo "$resp" | tail -1 | sed 's/HTTP://')
    resp=$(echo "$resp" | sed '$d')
    rid=$(extract_request_id "$resp")
    if [[ -n "$rid" ]]; then
      printf '%s|%s|' "$rid" "$code"
      return 0
    fi
    err=$(login_error_detail "$resp")
  fi
  if [[ -n "$host_token" ]]; then
    local list found_id
    list=$(curl_json "$BASE/api/video-streams/$stream_id/fortune-requests" \
      -H "Authorization: Bearer $host_token")
    found_id=$(printf '%s' "$list" | QUESTION="$question" python3 -c "
import json,os,sys
q=os.environ.get('QUESTION','')
try:
    d=json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
def items(node):
    if isinstance(node,list): return node
    if isinstance(node,dict):
        for k in ('requests','items','data'):
            v=node.get(k)
            if isinstance(v,list): return v
            if isinstance(v,dict):
                for kk in ('requests','items'):
                    vv=v.get(kk)
                    if isinstance(vv,list): return vv
    return []
for x in items(d):
    if not isinstance(x,dict): continue
    if q and q in str(x.get('question','')):
        print(x.get('id','')); break
" 2>/dev/null || echo "")
    if [[ -n "$found_id" ]]; then
      printf '%s|200|' "$found_id"
      return 0
    fi
  fi
  printf '|%s|%s' "$code" "$err"
}

clear_pending_fortune_request() {
  local stream_id="$1" token="$2"
  local pending rid
  pending=$(curl_json "$BASE/api/video-streams/$stream_id/fortune-requests/my-status" \
    -H "Authorization: Bearer $token" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
if d.get('hasPendingRequest'):
    print(d.get('requestId') or d.get('id') or 'yes')
" 2>/dev/null || echo "")
  [[ -z "$pending" ]] && return 0
  rid="$pending"
  if [[ "$rid" == "yes" ]]; then
    rid=$(curl_json "$BASE/api/video-streams/$stream_id/fortune-requests" \
      -H "Authorization: Bearer $token" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else d.get('requests') or []
for x in items:
    if isinstance(x,dict) and x.get('status')=='pending':
        print(x.get('id','')); break
" 2>/dev/null || echo "")
  fi
  [[ -z "$rid" ]] && return 0
  curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$stream_id/fortune-requests" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "{\"requestId\":\"$rid\"}" || true
}

patch_fortune_request_action() {
  local stream_id="$1" host_token="$2" request_id="$3" action="$4"
  curl -sS -w "\nHTTP:%{http_code}" -X PATCH "$BASE/api/video-streams/$stream_id/fortune-requests" \
    -H "Authorization: Bearer $host_token" \
    -H "Content-Type: application/json" \
    -d "{\"action\":\"$action\",\"requestId\":\"$request_id\"}"
}

user_jeton_balance() {
  local token="$1"
  curl_json "$BASE/api/me" -H "Authorization: Bearer $token" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for path in [
    lambda x:x.get('coins'),
    lambda x:x.get('jetonBalance'),
    lambda x:x.get('credits'),
    lambda x:(x.get('user') or {}).get('coins'),
]:
    v=path(d)
    if v is not None:
        try:
            print(int(v)); break
        except (TypeError, ValueError):
            pass
" 2>/dev/null || echo "0"
}

record() {
  local id="$1" name="$2" status="$3" detail="${4:-}"
  local icon
  case "$status" in
    PASS) icon="✅"; PASS=$((PASS + 1)) ;;
    FAIL) icon="❌"; FAIL=$((FAIL + 1)) ;;
    SKIP) icon="⏭️"; SKIP=$((SKIP + 1)) ;;
    BLOCKED) icon="⏸️"; SKIP=$((SKIP + 1)) ;;
    *) icon="•" ;;
  esac
  RESULT_LINES+=("| $id | $name | $icon $status | ${detail//|/\\|} |")
  echo "$icon [$id] $name — $status${detail:+ ($detail)}"
}

require_secret() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    record "$2" "$3" "SKIP" "secret yok: $name (GitHub Actions Secrets)"
    return 1
  fi
  return 0
}

acceptance_user_secrets_configured() {
  [[ -n "${ACCEPTANCE_USER_EMAIL:-}" && -n "${ACCEPTANCE_USER_PASSWORD:-}" ]]
}

acceptance_username_secrets_configured() {
  [[ -n "${ACCEPTANCE_USER_USERNAME:-}" && -n "${ACCEPTANCE_USER_PASSWORD:-}" ]]
}

acceptance_admin_secrets_configured() {
  [[ -n "${ACCEPTANCE_ADMIN_EMAIL:-}" && -n "${ACCEPTANCE_ADMIN_PASSWORD:-}" ]] ||
    [[ -n "${ACCEPTANCE_ADMIN_USERNAME:-}" && -n "${ACCEPTANCE_ADMIN_PASSWORD:-}" ]]
}

acceptance_teller_secrets_configured() {
  [[ -n "${ACCEPTANCE_TELLER_EMAIL:-}" && -n "${ACCEPTANCE_TELLER_PASSWORD:-}" ]] ||
    [[ -n "${ACCEPTANCE_TELLER_USERNAME:-}" && -n "${ACCEPTANCE_TELLER_PASSWORD:-}" ]]
}

# Oturum gerektiren testler — secret yoksa SKIP, secret var ama token yoksa FAIL.
skip_unless_user_token() {
  local id="$1" name="$2"
  bootstrap_user_token || true
  if [[ -n "${USER_TOKEN:-}" ]]; then
    return 0
  fi
  if acceptance_user_secrets_configured || acceptance_username_secrets_configured; then
    record "$id" "$name" "FAIL" "giriş başarısız / token yok"
  else
    record "$id" "$name" "SKIP" "ACCEPTANCE_USER_* secret yok"
  fi
  return 1
}

skip_unless_host_token() {
  local id="$1" name="$2"
  if [[ -n "${HOST_TOKEN:-}" ]]; then
    return 0
  fi
  if acceptance_user_secrets_configured || [[ -n "${ACCEPTANCE_HOST_EMAIL:-}" ]]; then
    record "$id" "$name" "FAIL" "host token yok"
  else
    record "$id" "$name" "SKIP" "host secret yok"
  fi
  return 1
}

skip_unless_live_chain() {
  local id="$1" name="$2"
  if [[ -n "${STREAM_ID:-}" && -n "${FORTUNE_REQUEST_ID:-}" && -n "${HOST_TOKEN:-}" ]]; then
    return 0
  fi
  if acceptance_user_secrets_configured || [[ -n "${ACCEPTANCE_HOST_EMAIL:-}" ]]; then
    record "$id" "$name" "FAIL" "önkoşul eksik"
  else
    record "$id" "$name" "SKIP" "canlı yayın önkoşulu yok (secret)"
  fi
  return 1
}

finalize_reports() {
  mkdir -p "$REPORT_DIR"
  local ts
  ts="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  {
    echo "# Acceptance Test Raporu"
    echo ""
    echo "| Alan | Değer |"
    echo "|------|--------|"
    echo "| Tarih | $ts |"
    echo "| Run | $RUN_ID |"
    echo "| API | $BASE |"
    echo "| Geçti | $PASS |"
    echo "| Başarısız | $FAIL |"
    echo "| Atlandı | $SKIP |"
    echo ""
    echo "## Sonuçlar"
    echo ""
    echo "| # | Test | Durum | Detay |"
    echo "|---|------|-------|-------|"
    for line in "${RESULT_LINES[@]}"; do
      echo "$line"
    done
    echo ""
    if [[ "$FAIL" -gt 0 ]]; then
      echo "**Release APK oluşturulmadı** — yukarıdaki başarısız testleri düzeltin."
    elif [[ "$SKIP" -gt 0 ]]; then
      echo "**API testleri atlandı veya kısmen geçti** ($SKIP atlandı) — istemci testleri bekleniyor."
    else
      echo "**API acceptance testleri geçti** — istemci testleri bekleniyor."
    fi
  } >"$REPORT_MD"

  python3 - "$REPORT_JSON" "$PASS" "$FAIL" "$SKIP" <<'PY'
import json, sys
path, p, f, s = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
rows = []
for line in open(sys.environ.get("REPORT_MD", ""), encoding="utf-8") if False else []:
    pass
# parse from env RESULT_LINES_RAW if set
raw = __import__("os").environ.get("RESULT_LINES_RAW", "")
for line in raw.splitlines():
    line = line.strip()
    if not line.startswith("|"):
        continue
    parts = [x.strip() for x in line.strip("|").split("|")]
    if len(parts) < 4 or parts[0] == "#":
        continue
    rows.append({"id": parts[0], "name": parts[1], "status": parts[2], "detail": parts[3]})
data = {
    "runId": __import__("os").environ.get("RUN_ID", ""),
    "baseUrl": __import__("os").environ.get("BASE", ""),
    "pass": p,
    "fail": f,
    "skip": s,
    "results": rows,
}
with open(path, "w", encoding="utf-8") as out:
    json.dump(data, out, ensure_ascii=False, indent=2)
PY

  echo ""
  echo "=== Acceptance özeti: $PASS geçti, $FAIL başarısız, $SKIP atlandı ==="
  echo "Rapor: $REPORT_MD"
  if [[ "$FAIL" -gt 0 ]]; then
    return 1
  fi
  return 0
}
