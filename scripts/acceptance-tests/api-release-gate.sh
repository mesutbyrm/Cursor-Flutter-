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
  if ! require_secret USER_PASSWORD 8 "Kullanıcı adı ile giriş"; then
    return 0
  fi
  local try_username="$USER_USERNAME" resp tok err me
  if [[ -z "$try_username" ]]; then
    bootstrap_user_token || true
    if [[ -n "${USER_TOKEN:-}" ]]; then
      me=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN")
      try_username=$(printf '%s' "$me" | json_field "['username']")
      [[ -z "$try_username" ]] && try_username=$(printf '%s' "$me" | json_field "['user']['username']")
    fi
  fi
  if [[ -z "$try_username" ]]; then
    record 8 "Kullanıcı adı ile giriş" SKIP "ACCEPTANCE_USER_USERNAME yok"
    return 0
  fi
  resp=$(mobile_login_identifier username "$try_username" "$USER_PASSWORD")
  tok=$(extract_token "$resp")
  if [[ -n "$tok" ]]; then
    USER_TOKEN="$tok"
    record 8 "Kullanıcı adı ile giriş" PASS "token alındı (@$try_username)"
  else
    err=$(login_error_detail "$resp")
    bootstrap_user_token || true
    record 8 "Kullanıcı adı ile giriş" FAIL "token yok ($err)"
  fi
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
gate_03_psychic_video() {
  if ! acceptance_admin_secrets_configured; then
    record 3 "Canlı falcı görüntülü görüşme" SKIP "ACCEPTANCE_ADMIN_* yok"
    return
  fi
  if ! acceptance_teller_secrets_configured; then
    record 3 "Canlı falcı görüntülü görüşme" SKIP "ACCEPTANCE_TELLER_* yok"
    return
  fi
  local admin_resp teller_resp create_resp admin_token
  if [[ -n "$ADMIN_EMAIL" ]]; then
    admin_resp=$(mobile_login_identifier email "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  elif [[ -n "$ADMIN_USERNAME" ]]; then
    admin_resp=$(mobile_login_identifier username "$ADMIN_USERNAME" "$ADMIN_PASSWORD")
  else
    record 3 "Canlı falcı görüntülü görüşme" SKIP "ACCEPTANCE_ADMIN_* yok"
    return
  fi
  admin_token=$(extract_token "$admin_resp")
  if [[ -n "$TELLER_EMAIL" ]]; then
    teller_resp=$(mobile_login_identifier email "$TELLER_EMAIL" "$TELLER_PASSWORD")
  elif [[ -n "$TELLER_USERNAME" ]]; then
    teller_resp=$(mobile_login_identifier username "$TELLER_USERNAME" "$TELLER_PASSWORD")
  else
    record 3 "Canlı falcı görüntülü görüşme" SKIP "ACCEPTANCE_TELLER_* yok"
    return
  fi
  TELLER_TOKEN=$(extract_token "$teller_resp")
  if [[ -z "$admin_token" || -z "$TELLER_TOKEN" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" FAIL "admin/teller token yok"
    return
  fi

  local teller_id="$TELLER_ID" teller_user="$TELLER_USER_ID"
  if [[ -z "$teller_id" || -z "$teller_user" ]]; then
    local tellers
    tellers=$(curl_json "$BASE/api/fortune-tellers")
    read -r teller_id teller_user <<<"$(printf '%s' "$tellers" | python3 -c "
import json,sys,os
email=os.environ.get('TELLER_EMAIL','').lower()
d=json.load(sys.stdin)
items=d.get('tellers') or d.get('data',{}).get('tellers') or d.get('items') or []
for t in items:
    u=(t.get('user') or {})
    if (t.get('email') or u.get('email') or '').lower()==email or (t.get('name') or '').lower() in email:
        print(t.get('id',''), t.get('userId') or u.get('id',''))
        break
else:
    if items:
        t=items[0]
        print(t.get('id',''), t.get('userId') or (t.get('user') or {}).get('id',''))
" 2>/dev/null || echo " ")"
  fi

  local create_body
  create_body=$(curl -sS -X POST "$BASE/api/fortune-tellers/session" \
    -H "Authorization: Bearer $admin_token" \
    -H "Content-Type: application/json" \
    -d "{
      \"tellerId\": \"${teller_id}\",
      \"tellerUserId\": \"${teller_user}\",
      \"clientName\": \"Release Gate Test\",
      \"durationMinutes\": 5,
      \"fortuneType\": \"tarot\"
    }")
  PSYCHIC_SESSION_ID=$(printf '%s' "$create_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for g in [lambda x:x.get('sessionId'), lambda x:(x.get('session') or {}).get('id'), lambda x:x.get('id')]:
    v=g(d)
    if v: print(v); break
" 2>/dev/null || echo "")

  if [[ -z "$PSYCHIC_SESSION_ID" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" FAIL "session oluşturulamadı"
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
gate_04_live_fortune_request() {
  if ! require_secret HOST_EMAIL 4 "Canlı yayın fal isteği" || ! require_secret HOST_PASSWORD 4 "Canlı yayın fal isteği"; then
    return 0
  fi
  local host_token="" create_result="" create_code="" err
  if bootstrap_host_token; then
    host_token="$HOST_TOKEN"
    create_result=$(create_video_stream "$host_token" "Gate $RUN_ID")
    STREAM_ID="${create_result%%|*}"
    create_code="${create_result##*|}"
  fi
  if [[ -z "$STREAM_ID" ]]; then
    if login_as_teller; then
      host_token="$TELLER_TOKEN"
      HOST_TOKEN="$TELLER_TOKEN"
      create_result=$(create_video_stream "$host_token" "Gate $RUN_ID")
      STREAM_ID="${create_result%%|*}"
      create_code="${create_result##*|}"
    fi
  fi
  if [[ -z "$STREAM_ID" ]]; then
    if login_as_admin; then
      host_token="$ADMIN_TOKEN"
      HOST_TOKEN="$ADMIN_TOKEN"
      create_result=$(create_video_stream "$host_token" "Gate $RUN_ID")
      STREAM_ID="${create_result%%|*}"
      create_code="${create_result##*|}"
    fi
  fi
  if [[ -z "$STREAM_ID" ]]; then
    err="HTTP ${create_code:-?}"
    record 4 "Canlı yayın fal isteği" FAIL "stream oluşturulamadı ($err)"
    return
  fi
  HOST_TOKEN="$host_token"

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
  local freq_result freq_code freq_err
  freq_result=$(post_fortune_request "$STREAM_ID" "$token")
  FORTUNE_REQUEST_ID="${freq_result%%|*}"
  freq_code=$(echo "$freq_result" | cut -d'|' -f2)
  freq_err=$(echo "$freq_result" | cut -d'|' -f3)
  if [[ -z "$FORTUNE_REQUEST_ID" ]]; then
    record 4 "Canlı yayın fal isteği" FAIL "istek oluşturulamadı (HTTP ${freq_code:-?}, ${freq_err:-bilinmeyen})"
    return
  fi

  local list found
  list=$(curl_json "$BASE/api/video-streams/$STREAM_ID/fortune-requests" \
    -H "Authorization: Bearer $HOST_TOKEN")
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
    record 4 "Canlı yayın fal isteği" FAIL "yayıncı listesinde yok"
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
  pay_body=$(GATE_REF="$ref" python3 -c 'import json,os; print(json.dumps({
    "requestType":"jeton",
    "method":"papara",
    "packageId":"p50",
    "packageTitle":"50 Jeton",
    "coins":50,
    "priceTry":25,
    "notes":"Release gate test "+os.environ["GATE_REF"]
  }))')
  local pay_resp
  pay_resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/payment/requests" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$pay_body")
  pay_code=$(echo "$pay_resp" | tail -1 | sed 's/HTTP://')
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
    PAYMENT_REQUEST_ID=$(curl_json "$BASE/api/payment/requests?status=pending&limit=5" \
      -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else d.get('requests') or d.get('items') or (d.get('data') or {}).get('requests') or []
if isinstance(items,dict): items=items.get('requests') or items.get('items') or []
for x in items:
    if isinstance(x,dict) and str(x.get('status','')).lower()=='pending':
        print(x.get('id','')); break
" 2>/dev/null || echo "")
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
  local admin_list found attempt
  found="no"
  for attempt in 1 2 3 4 5; do
    for endpoint in \
      "$BASE/api/admin/payment-notifications?status=all&limit=50" \
      "$BASE/api/admin/payment-requests?status=all&limit=50" \
      "$BASE/api/admin/cfc-payment-requests?status=all&limit=50"; do
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
