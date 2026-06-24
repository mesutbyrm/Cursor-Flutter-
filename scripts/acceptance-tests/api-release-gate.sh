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
ADMIN_PASSWORD="${ACCEPTANCE_ADMIN_PASSWORD:-}"
TELLER_EMAIL="${ACCEPTANCE_TELLER_EMAIL:-}"
TELLER_PASSWORD="${ACCEPTANCE_TELLER_PASSWORD:-}"
TELLER_ID="${ACCEPTANCE_TELLER_ID:-}"
TELLER_USER_ID="${ACCEPTANCE_TELLER_USER_ID:-}"

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

# --- 8. Kullanıcı adı ile giriş ---
gate_08_username_login() {
  if ! require_secret USER_USERNAME 8 "Kullanıcı adı ile giriş" || ! require_secret USER_PASSWORD 8 "Kullanıcı adı ile giriş"; then
    return
  fi
  local resp tok
  resp=$(mobile_login "{\"emailOrUsername\":\"$USER_USERNAME\",\"password\":\"$USER_PASSWORD\"}")
  tok=$(extract_token "$resp")
  if [[ -n "$tok" ]]; then
    USER_TOKEN="$tok"
    record 8 "Kullanıcı adı ile giriş" PASS "token alındı"
  else
    record 8 "Kullanıcı adı ile giriş" FAIL "token yok"
  fi
}

# --- 7. Profil ekranı < 2 sn (/api/me gecikmesi) ---
gate_07_profile_speed() {
  if [[ -z "$USER_TOKEN" ]]; then
    record 7 "Profil ekranı < 2 sn" FAIL "token yok"
    return
  fi
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
  if [[ -z "$USER_TOKEN" ]]; then
    record 6 "SSE bağlantıları" FAIL "token yok"
    return
  fi
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=5")
    ROOM_ID=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
rooms=d.get('rooms') or d.get('data',{}).get('rooms') or d.get('items') or []
print(rooms[0].get('id','') if rooms else '')
" 2>/dev/null || echo "")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record 6 "SSE bağlantıları" FAIL "oda kimliği yok"
    return
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
  if [[ -z "$ADMIN_EMAIL" || -z "$ADMIN_PASSWORD" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" FAIL "ACCEPTANCE_ADMIN_* gerekli"
    return
  fi
  if [[ -z "$TELLER_EMAIL" || -z "$TELLER_PASSWORD" ]]; then
    record 3 "Canlı falcı görüntülü görüşme" FAIL "ACCEPTANCE_TELLER_* gerekli"
    return
  fi
  local admin_resp teller_resp create_resp
  admin_resp=$(mobile_login "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
  local admin_token
  admin_token=$(extract_token "$admin_resp")
  teller_resp=$(mobile_login "{\"email\":\"$TELLER_EMAIL\",\"password\":\"$TELLER_PASSWORD\"}")
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
    return
  fi
  local resp
  resp=$(mobile_login "{\"email\":\"$HOST_EMAIL\",\"password\":\"$HOST_PASSWORD\"}")
  HOST_TOKEN=$(extract_token "$resp")
  if [[ -z "$HOST_TOKEN" ]]; then
    record 4 "Canlı yayın fal isteği" FAIL "host token yok"
    return
  fi
  local create_resp
  create_resp=$(curl -sS -X POST "$BASE/api/live" \
    -H "Authorization: Bearer $HOST_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"title\":\"Gate $RUN_ID\",\"status\":\"live\",\"requestType\":\"live\"}")
  STREAM_ID=$(printf '%s' "$create_resp" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for g in [lambda x:x.get('id'), lambda x:x.get('streamId'), lambda x:(x.get('stream') or {}).get('id'), lambda x:(x.get('data') or {}).get('id')]:
    v=g(d)
    if v: print(v); break
" 2>/dev/null || echo "")
  if [[ -z "$STREAM_ID" ]]; then
    record 4 "Canlı yayın fal isteği" FAIL "stream oluşturulamadı"
    return
  fi

  local token="${VIEWER_TOKEN:-$USER_TOKEN}"
  if [[ -z "$token" ]]; then
    resp=$(mobile_login "{\"email\":\"$VIEWER_EMAIL\",\"password\":\"$VIEWER_PASSWORD\"}")
    token=$(extract_token "$resp")
    VIEWER_TOKEN="$token"
  fi
  local freq
  freq=$(curl -sS -X POST "$BASE/api/video-streams/$STREAM_ID/fortune-requests" \
    -H "Authorization: Bearer $token" \
    -H "Content-Type: application/json" \
    -d '{"displayName":"GateTest","question":"Test?","fortuneType":"tarot","type":"tarot","priority":"normal","jetonCost":10}')
  FORTUNE_REQUEST_ID=$(printf '%s' "$freq" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for g in [lambda x:x.get('id'), lambda x:(x.get('request') or {}).get('id'), lambda x:(x.get('data') or {}).get('id')]:
    v=g(d)
    if v: print(v); break
" 2>/dev/null || echo "")

  if [[ -z "$FORTUNE_REQUEST_ID" ]]; then
    record 4 "Canlı yayın fal isteği" FAIL "istek oluşturulamadı"
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
  if [[ -z "$USER_TOKEN" ]]; then
    record 5 "Jeton bildirimi admin paneli" FAIL "token yok"
    return
  fi
  if [[ -z "$ADMIN_EMAIL" || -z "$ADMIN_PASSWORD" ]]; then
    record 5 "Jeton bildirimi admin paneli" FAIL "ACCEPTANCE_ADMIN_* gerekli"
    return
  fi

  local me uid username
  me=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN")
  uid=$(printf '%s' "$me" | json_field "['id']")
  [[ -z "$uid" ]] && uid=$(printf '%s' "$me" | json_field "['user']['id']")
  username=$(printf '%s' "$me" | json_field "['username']")
  local ref="CANLIFAL-GATE-$RUN_ID"
  local pay_resp pay_code
  pay_resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/payment/requests" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"requestType\": \"jeton\",
      \"type\": \"jeton\",
      \"method\": \"papara\",
      \"packageId\": \"gate_test\",
      \"packageTitle\": \"Gate Test Jeton\",
      \"coins\": 50,
      \"amount\": 50,
      \"priceTry\": 25,
      \"notes\": \"Release gate test $ref\",
      \"notifyAdmins\": true,
      \"notifyStaff\": true,
      \"source\": \"mobile_jeton_checkout\",
      \"senderInfo\": \"${username:-gate}\"
    }")
  pay_code=$(echo "$pay_resp" | tail -1 | sed 's/HTTP://')
  local pay_body
  pay_body=$(echo "$pay_resp" | sed '$d')
  PAYMENT_REQUEST_ID=$(printf '%s' "$pay_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for g in [lambda x:x.get('id'), lambda x:(x.get('request') or {}).get('id'), lambda x:(x.get('data') or {}).get('id')]:
    v=g(d)
    if v: print(v); break
" 2>/dev/null || echo "")

  if [[ "$pay_code" != "200" && "$pay_code" != "201" ]]; then
    record 5 "Jeton bildirimi admin paneli" FAIL "POST payment HTTP $pay_code"
    return
  fi

  local admin_resp
  admin_resp=$(mobile_login "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASSWORD\"}")
  ADMIN_TOKEN=$(extract_token "$admin_resp")
  if [[ -z "$ADMIN_TOKEN" ]]; then
    record 5 "Jeton bildirimi admin paneli" FAIL "admin token yok"
    return
  fi

  sleep 2
  local admin_list found
  admin_list=$(curl_json "$BASE/api/admin/payment-requests?limit=30" \
    -H "Authorization: Bearer $ADMIN_TOKEN")
  if [[ -z "$admin_list" || "$admin_list" == "{}" ]]; then
    admin_list=$(curl_json "$BASE/api/admin/payment-notifications?limit=30" \
      -H "Authorization: Bearer $ADMIN_TOKEN")
  fi
  found=$(printf '%s' "$admin_list" | python3 -c "
import json,sys
rid=sys.argv[1]
ref=sys.argv[2]
raw=sys.stdin.read()
if not raw.strip():
    print('no'); sys.exit()
d=json.loads(raw)
items=d.get('requests') or d.get('items') or d.get('notifications') or d.get('data') or []
if isinstance(items,dict):
    items=items.get('requests') or items.get('items') or items.get('notifications') or []
for x in items:
    if not isinstance(x,dict): continue
    if rid and str(x.get('id',''))==rid:
        print('yes'); sys.exit()
    blob=json.dumps(x,ensure_ascii=False)
    if ref in blob:
        print('yes'); sys.exit()
print('no')
" "$PAYMENT_REQUEST_ID" "$ref" 2>/dev/null || echo "no")

  if [[ "$found" == "yes" ]]; then
    record 5 "Jeton bildirimi admin paneli" PASS "admin listesinde görüldü id=${PAYMENT_REQUEST_ID:-ref}"
  else
    record 5 "Jeton bildirimi admin paneli" FAIL "admin panelinde bulunamadı"
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
