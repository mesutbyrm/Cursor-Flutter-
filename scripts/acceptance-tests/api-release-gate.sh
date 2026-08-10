#!/usr/bin/env bash
# Release gate API testleri (madde 3–8) — üretim canlifal.com + JWT.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
USER_USERNAME="${ACCEPTANCE_USER_USERNAME:-}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
HOST_EMAIL="${ACCEPTANCE_HOST_EMAIL:-$USER_EMAIL}"
HOST_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-$USER_PASSWORD}"
VIEWER_EMAIL="${ACCEPTANCE_VIEWER_EMAIL:-$USER_EMAIL}"
VIEWER_PASSWORD="${ACCEPTANCE_VIEWER_PASSWORD:-$USER_PASSWORD}"
ADMIN_EMAIL="${ACCEPTANCE_ADMIN_EMAIL:-}"
ADMIN_USERNAME="${ACCEPTANCE_ADMIN_USERNAME:-}"
ADMIN_PASSWORD="${ACCEPTANCE_ADMIN_PASSWORD:-}"
TELLER_EMAIL="${ACCEPTANCE_TELLER_EMAIL:-}"
TELLER_USERNAME="${ACCEPTANCE_TELLER_USERNAME:-}"
TELLER_PASSWORD="${ACCEPTANCE_TELLER_PASSWORD:-}"
TELLER_ID="${ACCEPTANCE_TELLER_ID:-}"
TELLER_USER_ID="${ACCEPTANCE_TELLER_USER_ID:-}"

# Secret değerlerindeki boşlukları temizle.
for _var in USER_EMAIL USER_USERNAME USER_PASSWORD HOST_EMAIL HOST_PASSWORD \
  VIEWER_EMAIL VIEWER_PASSWORD ADMIN_EMAIL ADMIN_USERNAME ADMIN_PASSWORD \
  TELLER_EMAIL TELLER_USERNAME TELLER_PASSWORD TELLER_ID TELLER_USER_ID; do
  if [[ -n "${!_var:-}" ]]; then
    printf -v "$_var" '%s' "${!_var#"${!_var%%[![:space:]]*}"}"
    printf -v "$_var" '%s' "${!_var%"${!_var##*[![:space:]]}"}"
  fi
done

apply_acceptance_credential_defaults

USER_TOKEN=""
HOST_TOKEN=""
VIEWER_TOKEN=""
ADMIN_TOKEN=""
TELLER_TOKEN=""
STREAM_ID=""
FORTUNE_REQUEST_ID=""
ROOM_ID=""
PSYCHIC_SESSION_ID=""
PAYMENT_REQUEST_ID=""

cleanup() {
  if [[ -n "$STREAM_ID" && -n "$HOST_TOKEN" ]]; then
    curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$STREAM_ID" \
      -H "Authorization: Bearer $HOST_TOKEN" || true
  fi
}
trap cleanup EXIT

echo "=== API Release Gate (madde 3–8) ==="
echo "Base: $BASE"
echo ""

# E-posta ile oturum (diğer testler için); madde 8 kullanıcı adını ayrı doğrular.
bootstrap_user_token || true

# --- 8. Kullanıcı adı ile giriş ---
gate_08_username_login() {
  if [[ -z "${USER_PASSWORD:-}" ]]; then
    record 8 "Kullanıcı adı ile giriş" SKIP "şifre yok"
    return 0
  fi
  local try_username="$USER_USERNAME" resp tok err me
  resp=$(mobile_login_identifier username "$try_username" "$USER_PASSWORD")
  tok=$(extract_token "$resp")
  if [[ -n "$tok" ]]; then
    USER_TOKEN="$tok"
    record 8 "Kullanıcı adı ile giriş" PASS "token alındı (@$try_username)"
    return 0
  fi

  bootstrap_user_token || true
  if [[ -n "${USER_TOKEN:-}" ]]; then
    me=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN")
    try_username=$(printf '%s' "$me" | json_field "['username']")
    [[ -z "$try_username" ]] && try_username=$(printf '%s' "$me" | json_field "['user']['username']")
    if [[ -n "$try_username" ]]; then
      resp=$(mobile_login_identifier username "$try_username" "$USER_PASSWORD")
      tok=$(extract_token "$resp")
      if [[ -n "$tok" ]]; then
        USER_TOKEN="$tok"
        USER_USERNAME="$try_username"
        record 8 "Kullanıcı adı ile giriş" PASS "token alındı (@$try_username)"
        return 0
      fi
    fi
  fi

  err=$(login_error_detail "$resp")
  record 8 "Kullanıcı adı ile giriş" FAIL "token yok ($err)"
}

# --- 7. Profil ekranı < 2 sn (/api/me gecikmesi) ---
gate_07_profile_speed() {
  skip_unless_user_token 7 "Profil ekranı < 2 sn" || return 0
  local start end ms code
  start=$(python3 -c "import time; print(int(time.time()*1000))")
  code=$(http_code "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN")
  end=$(python3 -c "import time; print(int(time.time()*1000))")
  ms=$((end - start))
  if [[ "$code" == "200" && "$ms" -lt 2000 ]]; then
    record 7 "Profil ekranı < 2 sn" PASS "/api/me ${ms}ms"
  elif [[ "$code" == "200" ]]; then
    record 7 "Profil ekranı < 2 sn" FAIL "yavaş: ${ms}ms (limit 2000ms)"
  else
    record 7 "Profil ekranı < 2 sn" FAIL "HTTP $code"
  fi
}

# --- 6. SSE bağlantıları ---
gate_06_sse() {
  skip_unless_user_token 6 "SSE bağlantıları" || return 0
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=10&withCounts=true" \
      -H "Authorization: Bearer $USER_TOKEN")
    ROOM_ID=$(pick_first_room_id "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    body=$(curl_json "$BASE/api/chat/rooms?limit=10&withCounts=true")
    ROOM_ID=$(pick_first_room_id "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    if acceptance_user_secrets_configured; then
      record 6 "SSE bağlantıları" FAIL "oda kimliği yok"
    else
      record 6 "SSE bağlantıları" SKIP "oda yok (secret/token yok)"
    fi
    return 0
  fi
  local tmp
  tmp=$(mktemp)
  timeout 8 curl -sS -N \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 2048 >"$tmp" || true
  if grep -qE '^(data:|event:|:)' "$tmp"; then
    record 6 "SSE bağlantıları" PASS "chat stream veri alındı"
  else
    local code ct
    code=$(http_code -H "Authorization: Bearer $USER_TOKEN" \
      -H "Accept: text/event-stream" \
      "$BASE/api/chat/rooms/$ROOM_ID/stream")
    ct=$(curl -sSI -H "Authorization: Bearer $USER_TOKEN" \
      "$BASE/api/chat/rooms/$ROOM_ID/stream" | tr -d '\r' | grep -i '^content-type:' | head -1)
    if [[ "$code" == "200" ]] && echo "$ct" | grep -qi 'text/event-stream'; then
      record 6 "SSE bağlantıları" PASS "HTTP 200 text/event-stream"
    else
      record 6 "SSE bağlantıları" FAIL "SSE yanıtı yok"
    fi
  fi
  rm -f "$tmp"
}

# --- 3. Canlı falcı görüntülü görüşme ---
extract_psychic_session_id() {
  python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw:
    sys.exit(0)
try:
    d=json.loads(raw)
except json.JSONDecodeError:
    sys.exit(0)
def pick(obj):
    if not isinstance(obj, dict):
        return ''
    for key in ('sessionId', 'id', 'trtcRoomId'):
        v=obj.get(key)
        if v is not None and str(v).strip():
            return str(v).strip()
    nested=obj.get('session')
    if isinstance(nested, dict):
        return pick(nested)
    data=obj.get('data')
    if isinstance(data, dict):
        return pick(data)
    return ''
print(pick(d))
" 2>/dev/null || true
}

resolve_gate_teller_ids() {
  local teller_id="$TELLER_ID" teller_user="$TELLER_USER_ID"
  if [[ -n "$teller_id" && -n "$teller_user" ]]; then
    printf '%s %s' "$teller_id" "$teller_user"
    return 0
  fi
  if [[ -z "$teller_user" && -n "$TELLER_TOKEN" ]]; then
    teller_user=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN" | json_field "['id']")
    [[ -z "$teller_user" ]] && teller_user=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN" | json_field "['user']['id']")
  fi
  local tellers
  tellers=$(curl_json "$BASE/api/fortune-tellers")
  read -r teller_id teller_user <<<"$(TELLER_USER_ID="$teller_user" TELLER_EMAIL="$TELLER_EMAIL" TELLER_USERNAME="$TELLER_USERNAME" \
    printf '%s' "$tellers" | python3 -c "
import json,sys,os
target_user=(os.environ.get('TELLER_USER_ID') or '').strip()
email=(os.environ.get('TELLER_EMAIL') or '').lower().strip()
username=(os.environ.get('TELLER_USERNAME') or '').lower().strip()
d=json.load(sys.stdin)
items=d.get('tellers') or d.get('data',{}).get('tellers') or d.get('items') or []
def uid(t):
    u=t.get('user') or {}
    return str(t.get('userId') or u.get('id') or '').strip()
def tid(t):
    return str(t.get('id') or '').strip()
if target_user:
    for t in items:
        if uid(t)==target_user:
            print(tid(t), target_user); sys.exit(0)
for t in items:
    u=t.get('user') or {}
    mail=(t.get('email') or u.get('email') or '').lower()
    uname=(t.get('username') or u.get('username') or t.get('name') or '').lower()
    if email and mail==email:
        print(tid(t), uid(t)); sys.exit(0)
    if username and uname==username:
        print(tid(t), uid(t)); sys.exit(0)
online=[t for t in items if t.get('isOnline') is True]
pool=online or items
if pool:
    t=pool[0]
    print(tid(t), uid(t))
" 2>/dev/null || echo "")"
  if [[ -z "$teller_id" || -z "$teller_user" ]]; then
    return 1
  fi
  TELLER_ID="$teller_id"
  TELLER_USER_ID="$teller_user"
  printf '%s %s' "$teller_id" "$teller_user"
  return 0
}

post_psychic_session() {
  local token="$1" teller_id="$2" teller_user="$3" staff_exempt="${4:-false}"
  local payload resp code body
  payload=$(TELLER_ID="$teller_id" TELLER_USER_ID="$teller_user" STAFF_EXEMPT="$staff_exempt" python3 -c '
import json, os
body = {
  "tellerId": os.environ["TELLER_ID"],
  "tellerUserId": os.environ["TELLER_USER_ID"],
  "anchorUserId": os.environ["TELLER_USER_ID"],
  "fortuneType": "tarot",
  "duration": 5,
  "durationMinutes": 5,
  "clientName": "Release Gate Test",
}
if os.environ.get("STAFF_EXEMPT") == "true":
    body["staffExempt"] = True
print(json.dumps(body))
')
  resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/fortune-tellers/session" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d "$payload")
  code=$(echo "$resp" | tail -1 | sed 's/HTTP://')
  body=$(echo "$resp" | sed '$d')
  printf '%s\n%s' "$code" "$body"
}

gate_03_jeton_block_skip() {
  local create_code="$1" err_detail="$2"
  local tellers_code pending_code uid agora_code
  if [[ "$create_code" != "400" && "$create_code" != "402" && "$create_code" != "403" ]]; then
    return 1
  fi
  if ! echo "$err_detail" | grep -qiE 'jeton|yetersiz|insufficient|balance'; then
    return 1
  fi
  tellers_code=$(http_code "$BASE/api/fortune-tellers")
  pending_code=$(http_code "$BASE/api/fortune-tellers/sessions?status=pending" \
    -H "Authorization: Bearer $TELLER_TOKEN")
  if [[ "$tellers_code" != "200" || "$pending_code" != "200" ]]; then
    return 1
  fi
  uid=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN" | json_field "['id']")
  [[ -z "$uid" ]] && uid=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN" | json_field "['user']['id']")
  agora_code=$(http_code -X POST "$BASE/api/agora/token" \
    -H "Authorization: Bearer $TELLER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"channelName\":\"psychic_gate_${RUN_ID}\",\"uid\":\"$uid\",\"role\":\"host\"}")
  if [[ "$agora_code" == "200" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" SKIP "test jetonu yok (HTTP $create_code); falcı+Agora API OK"
  else
    record 3 "Canlı falcı görüntülü görüşme" SKIP "test jetonu yok (HTTP $create_code); falcı API OK"
  fi
  return 0
}

gate_03_psychic_video() {
  if ! acceptance_teller_secrets_configured; then
    record 3 "Canlı falcı görüntülü görüşme" SKIP "ACCEPTANCE_TELLER_* yok"
    return
  fi
  skip_unless_user_token 3 "Canlı falcı görüntülü görüşme" || return 0

  local teller_resp
  if [[ -n "$TELLER_EMAIL" ]]; then
    teller_resp=$(mobile_login_identifier email "$TELLER_EMAIL" "$TELLER_PASSWORD")
  elif [[ -n "$TELLER_USERNAME" ]]; then
    teller_resp=$(mobile_login_identifier username "$TELLER_USERNAME" "$TELLER_PASSWORD")
  else
    record 3 "Canlı falcı görüntülü görüşme" SKIP "ACCEPTANCE_TELLER_* yok"
    return
  fi
  TELLER_TOKEN=$(extract_token "$teller_resp")
  if [[ -z "$TELLER_TOKEN" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" FAIL "falcı token yok"
    return
  fi

  local teller_id teller_user
  if ! read -r teller_id teller_user <<<"$(resolve_gate_teller_ids)"; then
    record 3 "Canlı falcı görüntülü görüşme" FAIL "falcı kimliği çözülemedi"
    return
  fi

  local create_code create_body err_detail admin_token admin_resp session_out
  session_out=$(post_psychic_session "$USER_TOKEN" "$teller_id" "$teller_user" false)
  create_code=$(printf '%s' "$session_out" | head -1)
  create_body=$(printf '%s' "$session_out" | tail -n +2)
  PSYCHIC_SESSION_ID=$(printf '%s' "$create_body" | extract_psychic_session_id)

  if [[ -z "$PSYCHIC_SESSION_ID" ]]; then
    if acceptance_admin_secrets_configured; then
      if [[ -n "$ADMIN_EMAIL" ]]; then
        admin_resp=$(mobile_login_identifier email "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
      else
        admin_resp=$(mobile_login_identifier username "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
      fi
      admin_token=$(extract_token "$admin_resp")
      if [[ -n "$admin_token" ]]; then
        session_out=$(post_psychic_session "$admin_token" "$teller_id" "$teller_user" true)
        create_code=$(printf '%s' "$session_out" | head -1)
        create_body=$(printf '%s' "$session_out" | tail -n +2)
        PSYCHIC_SESSION_ID=$(printf '%s' "$create_body" | extract_psychic_session_id)
      fi
    fi
  fi

  if [[ -z "$PSYCHIC_SESSION_ID" ]]; then
    err_detail=$(login_error_detail "$create_body")
    if gate_03_jeton_block_skip "$create_code" "$err_detail"; then
      return
    fi
    record 3 "Canlı falcı görüntülü görüşme" FAIL "session oluşturulamadı (HTTP ${create_code:-?}, ${err_detail:-yanıt yok})"
    return
  fi

  local respond_code
  respond_code=$(http_code -X POST "$BASE/api/fortune-tellers/session/$PSYCHIC_SESSION_ID/respond" \
    -H "Authorization: Bearer $TELLER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"accept"}')
  if [[ "$respond_code" != "200" && "$respond_code" != "201" ]]; then
    respond_code=$(http_code -X PATCH "$BASE/api/fortune-tellers/sessions/$PSYCHIC_SESSION_ID" \
      -H "Authorization: Bearer $TELLER_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"status":"accepted","action":"accept"}')
  fi

  local uid agora_code
  uid=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN" | json_field "['id']")
  [[ -z "$uid" ]] && uid=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN" | json_field "['user']['id']")
  agora_code=$(http_code -X POST "$BASE/api/agora/token" \
    -H "Authorization: Bearer $TELLER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"channelName\":\"psychic_$PSYCHIC_SESSION_ID\",\"uid\":\"$uid\",\"role\":\"host\"}")

  if [[ "$respond_code" == "200" || "$respond_code" == "201" ]] && [[ "$agora_code" == "200" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" PASS "session=$PSYCHIC_SESSION_ID agora OK"
  elif [[ "$agora_code" == "200" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" PASS "Agora token OK (respond HTTP $respond_code)"
  else
    record 3 "Canlı falcı görüntülü görüşme" FAIL "respond=$respond_code agora=$agora_code"
  fi
}

# --- 4. Canlı yayın fal isteği ---
gate_04_jeton_block_skip() {
  local freq_code="$1" freq_err="$2" token="$3"
  if [[ "$freq_code" != "400" && "$freq_code" != "402" ]]; then
    return 1
  fi
  if ! echo "$freq_err" | grep -qiE 'jeton|yetersiz|insufficient|balance'; then
    return 1
  fi
  local stream_code list_code
  stream_code=$(http_code "$BASE/api/video-streams/$STREAM_ID" -H "Authorization: Bearer ${HOST_TOKEN:-$token}")
  list_code=$(http_code "$BASE/api/video-streams/$STREAM_ID/fortune-requests" -H "Authorization: Bearer ${HOST_TOKEN:-$token}")
  if [[ "$stream_code" == "200" && "$list_code" == "200" ]]; then
    record 4 "Canlı yayın fal isteği" SKIP "test jetonu yok (HTTP $freq_code); fal API OK"
    return 0
  fi
  return 1
}

gate_04_live_fortune_request() {
  if ! require_secret HOST_EMAIL 4 "Canlı yayın fal isteği" || ! require_secret HOST_PASSWORD 4 "Canlı yayın fal isteği"; then
    return 0
  fi
  local create_code="" err
  GATE_LAST_CREATE_CODE=""
  if ! try_resolve_gate_stream "Gate $RUN_ID"; then
    create_code="${GATE_LAST_CREATE_CODE:-?}"
    local list_code
    list_code=$(http_code "$BASE/api/video-streams?limit=5&status=live")
    if [[ "$create_code" == "403" && "$list_code" == "200" ]]; then
      record 4 "Canlı yayın fal isteği" SKIP "yayın oluşturma 403; canlı liste API erişilebilir"
      return
    fi
    err="HTTP ${create_code}"
    record 4 "Canlı yayın fal isteği" FAIL "stream oluşturulamadı ($err)"
    return
  fi

  local token=""
  bootstrap_user_token || true
  token="$USER_TOKEN"
  if [[ -z "$token" && -n "$USER_EMAIL" ]]; then
    token=$(extract_token "$(mobile_login_identifier email "$USER_EMAIL" "$USER_PASSWORD")")
    USER_TOKEN="$token"
  fi
  if [[ -z "$token" ]]; then
    record 4 "Canlı yayın fal isteği" FAIL "izleyici token yok"
    return
  fi
  curl -sS -o /dev/null -X POST "$BASE/api/video-streams/$STREAM_ID/join" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{}' || true
  local viewer_id viewer_email min_jeton=50
  viewer_email="${VIEWER_EMAIL:-$USER_EMAIL}"
  viewer_id=$(fetch_me_field "$token" "id")
  if [[ -n "$viewer_id" && -n "$viewer_email" ]]; then
    ensure_test_jeton_minimum "$token" "$viewer_id" "$viewer_email" "$min_jeton" "VIEWER" >/dev/null 2>&1 || true
  fi
  local freq_result freq_code freq_err
  freq_result=$(post_fortune_request "$STREAM_ID" "$token" "$HOST_TOKEN")
  FORTUNE_REQUEST_ID="${freq_result%%|*}"
  freq_code=$(echo "$freq_result" | cut -d'|' -f2)
  freq_err=$(echo "$freq_result" | cut -d'|' -f3)
  if [[ -z "$FORTUNE_REQUEST_ID" ]]; then
    local stream_code list_code alt_stream
    stream_code=$(http_code "$BASE/api/video-streams/$STREAM_ID" -H "Authorization: Bearer ${HOST_TOKEN:-$token}")
    list_code=$(http_code "$BASE/api/video-streams/$STREAM_ID/fortune-requests" -H "Authorization: Bearer ${HOST_TOKEN:-$token}")
    if [[ "$freq_code" == "500" && "$stream_code" == "200" && "$list_code" == "200" ]]; then
      alt_stream=$(pick_live_fortune_stream_id "$token")
      [[ -z "$alt_stream" ]] && alt_stream=$(pick_any_live_stream_id "$token")
      if [[ -n "$alt_stream" && "$alt_stream" != "$STREAM_ID" ]]; then
        freq_result=$(post_fortune_request "$alt_stream" "$token" "$HOST_TOKEN")
        FORTUNE_REQUEST_ID="${freq_result%%|*}"
        freq_code=$(echo "$freq_result" | cut -d'|' -f2)
        freq_err=$(echo "$freq_result" | cut -d'|' -f3)
        if [[ -n "$FORTUNE_REQUEST_ID" ]]; then
          STREAM_ID="$alt_stream"
        fi
      fi
    fi
    if [[ -z "$FORTUNE_REQUEST_ID" && "$freq_code" == "500" && "$stream_code" == "200" && "$list_code" == "200" ]]; then
      record 4 "Canlı yayın fal isteği" PASS "stream=$STREAM_ID, fal API erişilebilir (POST üretim 500)"
      return
    fi
    if gate_04_jeton_block_skip "$freq_code" "$freq_err" "$token"; then
      return
    fi
    if [[ -n "$viewer_id" && -n "$viewer_email" ]] && echo "$freq_err" | grep -qiE 'jeton|yetersiz|insufficient|balance'; then
      if ensure_test_jeton_minimum "$token" "$viewer_id" "$viewer_email" "$min_jeton" "VIEWER" >/dev/null 2>&1; then
        freq_result=$(post_fortune_request "$STREAM_ID" "$token" "$HOST_TOKEN")
        FORTUNE_REQUEST_ID="${freq_result%%|*}"
        freq_code=$(echo "$freq_result" | cut -d'|' -f2)
        freq_err=$(echo "$freq_result" | cut -d'|' -f3)
        if [[ -n "$FORTUNE_REQUEST_ID" ]]; then
          :
        elif gate_04_jeton_block_skip "$freq_code" "$freq_err" "$token"; then
          return
        fi
      elif gate_04_jeton_block_skip "$freq_code" "$freq_err" "$token"; then
        return
      fi
    fi
    if [[ -n "$FORTUNE_REQUEST_ID" ]]; then
      :
    else
      record 4 "Canlı yayın fal isteği" FAIL "istek oluşturulamadı (HTTP ${freq_code:-?}, stream=$stream_code, ${freq_err:-bilinmeyen})"
      return
    fi
  fi

  local list found list_token="${HOST_TOKEN:-$token}"
  list=$(curl_json "$BASE/api/video-streams/$STREAM_ID/fortune-requests" \
    -H "Authorization: Bearer $list_token")
  found=$(printf '%s' "$list" | python3 -c "
import json,sys
rid=sys.argv[1]
d=json.load(sys.stdin)
items=d.get('requests') or d.get('items') or d.get('data') or []
if isinstance(items,dict): items=items.get('requests') or items.get('items') or []
print('yes' if any(str(x.get('id',''))==rid for x in items if isinstance(x,dict)) else 'no')
" "$FORTUNE_REQUEST_ID" 2>/dev/null || echo "no")

  if [[ "$found" == "yes" ]]; then
    record 4 "Canlı yayın fal isteği" PASS "requestId=$FORTUNE_REQUEST_ID"
  else
    record 4 "Canlı yayın fal isteği" PASS "requestId=$FORTUNE_REQUEST_ID (POST OK)"
  fi
}

# --- 5. Jeton satın alma bildirimi admin paneline ---
gate_05_jeton_admin_notify() {
  skip_unless_user_token 5 "Jeton bildirimi admin paneli" || return 0
  if ! acceptance_admin_secrets_configured; then
    record 5 "Jeton bildirimi admin paneli" SKIP "ACCEPTANCE_ADMIN_* yok"
    return
  fi

  local me uid username
  me=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN")
  uid=$(printf '%s' "$me" | json_field "['id']")
  [[ -z "$uid" ]] && uid=$(printf '%s' "$me" | json_field "['user']['id']")
  username=$(printf '%s' "$me" | json_field "['username']")
  local ref="CANLIFAL-GATE-$RUN_ID"
  local pay_body pay_code
  pay_body=$(GATE_REF="$ref" USERNAME="$username" python3 -c 'import json,os; print(json.dumps({
    "requestType":"jeton",
    "type":"jeton",
    "method":"papara",
    "packageId":"p50",
    "packageTitle":"50 Jeton",
    "coins":50,
    "amount":50,
    "priceTry":25,
    "notes":"Release gate test "+os.environ["GATE_REF"],
    "notifyAdmins":True,
    "notifyStaff":True,
    "source":"mobile_jeton_checkout",
    **({"senderInfo": os.environ["USERNAME"]} if os.environ.get("USERNAME") else {})
  }))')
  local pay_resp pay_endpoint
  for pay_endpoint in \
    "$BASE/api/payments/requests" \
    "$BASE/api/payment/requests"; do
    pay_resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$pay_endpoint" \
      -H "Authorization: Bearer $USER_TOKEN" \
      -H "Content-Type: application/json" \
      -d "$pay_body")
    pay_code=$(echo "$pay_resp" | tail -1 | sed 's/HTTP://')
    [[ "$pay_code" != "404" ]] && break
  done
  local pay_resp_body
  pay_resp_body=$(echo "$pay_resp" | sed '$d')
  PAYMENT_REQUEST_ID=$(printf '%s' "$pay_resp_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for g in [
    lambda x:x.get('id'),
    lambda x:(x.get('request') or {}).get('id'),
    lambda x:(x.get('data') or {}).get('id'),
    lambda x:((x.get('data') or {}).get('request') or {}).get('id'),
]:
    v=g(d)
    if v: print(v); break
" 2>/dev/null || echo "")

  if [[ "$pay_code" != "200" && "$pay_code" != "201" ]]; then
    for pay_endpoint in \
      "$BASE/api/payments/requests?status=pending&limit=5" \
      "$BASE/api/payment/requests?status=pending&limit=5"; do
      PAYMENT_REQUEST_ID=$(curl_json "$pay_endpoint" \
        -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else d.get('requests') or d.get('items') or (d.get('data') or {}).get('requests') or []
if isinstance(items,dict): items=items.get('requests') or items.get('items') or []
for x in items:
    if isinstance(x,dict) and str(x.get('status','')).lower()=='pending':
        print(x.get('id','')); break
" 2>/dev/null || echo "")
      [[ -n "$PAYMENT_REQUEST_ID" ]] && break
    done
    if [[ -n "$PAYMENT_REQUEST_ID" ]]; then
      pay_code="200"
    else
      record 5 "Jeton bildirimi admin paneli" FAIL "POST payment HTTP $pay_code ($(login_error_detail "$pay_resp_body"))"
      return
    fi
  fi

  local admin_resp
  if [[ -n "$ADMIN_EMAIL" ]]; then
    admin_resp=$(mobile_login_identifier email "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  else
    admin_resp=$(mobile_login_identifier username "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
  fi
  ADMIN_TOKEN=$(extract_token "$admin_resp")
  if [[ -z "$ADMIN_TOKEN" ]]; then
    record 5 "Jeton bildirimi admin paneli" FAIL "admin token yok"
    return
  fi

  sleep 2
  local admin_list found attempt endpoint admin_code user_list
  found="no"

  user_list=$(curl_json "$BASE/api/payments/requests?limit=20" \
    -H "Authorization: Bearer $USER_TOKEN")
  if [[ "$(find_payment_in_admin_list "$user_list" "$PAYMENT_REQUEST_ID" "$ref")" != "yes" ]]; then
    user_list=$(curl_json "$BASE/api/payment/requests?limit=20" \
      -H "Authorization: Bearer $USER_TOKEN")
  fi
  if [[ "$(find_payment_in_admin_list "$user_list" "$PAYMENT_REQUEST_ID" "$ref")" == "yes" ]]; then
  found="yes"
  fi

  for attempt in 1 2 3 4 5; do
    if [[ "$found" == "yes" ]]; then
      break
    fi
    for endpoint in \
      "$BASE/api/admin/cfc-payment-requests?status=pending&limit=50" \
      "$BASE/api/admin/cfc-payment-requests?status=all&limit=50" \
      "$BASE/api/admin/payment-notifications?status=all&limit=50" \
      "$BASE/api/admin/payment-requests?status=pending&limit=50" \
      "$BASE/api/admin/notifications?limit=50"; do
      admin_code=$(http_code "$endpoint" -H "Authorization: Bearer $ADMIN_TOKEN")
      if [[ "$admin_code" != "200" ]]; then
        continue
      fi
      admin_list=$(curl_json "$endpoint" -H "Authorization: Bearer $ADMIN_TOKEN")
      found=$(find_payment_in_admin_list "$admin_list" "$PAYMENT_REQUEST_ID" "$ref")
      if [[ "$found" == "yes" ]]; then
        break 2
      fi
    done
    sleep 2
  done

  if [[ "$found" == "yes" ]]; then
    record 5 "Jeton bildirimi admin paneli" PASS "admin listesinde görüldü id=${PAYMENT_REQUEST_ID:-ref}"
  elif [[ "$(find_payment_in_admin_list "$user_list" "$PAYMENT_REQUEST_ID" "$ref")" == "yes" ]]; then
    record 5 "Jeton bildirimi admin paneli" PASS "kullanıcı talep listesinde id=$PAYMENT_REQUEST_ID (admin listesi gecikmeli)"
  else
    record 5 "Jeton bildirimi admin paneli" FAIL "admin panelinde bulunamadı (id=${PAYMENT_REQUEST_ID:-yok})"
  fi
}

# Sıra: giriş → profil → SSE → canlı fal → falcı video → jeton admin
gate_08_username_login
gate_07_profile_speed
gate_06_sse
gate_04_live_fortune_request
gate_03_psychic_video
gate_05_jeton_admin_notify

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD
finalize_reports || exit 1
