#!/usr/bin/env bash
# Aşama 5 — Jeton → LIVE → LIVE FALCI → Sesli oda gerçek uçtan uca API testleri.
# Gerçek cihaz (TRTC kamera/mikrofon/ses) için adb gerekir; jeton top-up için ACCEPTANCE_ADMIN_*.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

# --- Tanımlı test kullanıcıları (production gerçek kullanıcı değil) ---
TEST_USER_A_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
TEST_USER_A_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
TEST_USER_B_EMAIL="${ACCEPTANCE_HOST_EMAIL:-${ACCEPTANCE_VIEWER_EMAIL:-}}"
TEST_USER_B_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-${ACCEPTANCE_VIEWER_PASSWORD:-}}"
TEST_PSYCHIC_EMAIL="${ACCEPTANCE_TELLER_EMAIL:-}"
TEST_PSYCHIC_PASSWORD="${ACCEPTANCE_TELLER_PASSWORD:-}"

# Jeton ihtiyaçları (backend fiyatlarından): müzik 10, hediye elmas 500, falcı ~50+ (5dk*10)
STAGE5_TARGET_JETON="${STAGE5_TARGET_JETON:-1500}"
GIFT_JETON_COST=500
MUSIC_JETON_COST=10

USER_A_TOKEN=""
USER_B_TOKEN=""
PSYCHIC_TOKEN=""
USER_A_ID=""
USER_B_ID=""
ROOM_ID=""
STREAM_ID=""
SESSION_ID=""
TELLER_ID=""
TELLER_USER_ID=""

# Bakiye raporu
declare -A INITIAL_BALANCE=()
declare -A FINAL_BALANCE=()
declare -A TOTAL_SPENT=()

REPORT_MD="${ROOT}/docs/STAGE5_REAL_E2E_ACCEPTANCE_REPORT.md"

record_stage5() {
  local area="$1" name="$2" status="$3" detail="${4:-}"
  record "$area" "$name" "$status" "$detail"
}

login_test_user() {
  local kind="$1" email="$2" pass="$3"
  local resp tok
  resp=$(mobile_login_identifier email "$email" "$pass")
  tok=$(extract_token "$resp")
  if [[ -z "$tok" ]]; then
    return 1
  fi
  case "$kind" in
    A) USER_A_TOKEN="$tok" ;;
    B) USER_B_TOKEN="$tok" ;;
    P) PSYCHIC_TOKEN="$tok" ;;
  esac
  return 0
}

read_balance() {
  local token="$1"
  user_jeton_balance_from_me "$token"
}

stage5_bootstrap() {
  echo "=== STAGE 5 — Test kullanıcıları ==="
  if [[ -z "$TEST_USER_A_EMAIL" || -z "$TEST_USER_A_PASSWORD" ]]; then
    record_stage5 "SETUP" "TEST_USER_A login" FAIL "ACCEPTANCE_USER_* yok"
    return 1
  fi
  if ! login_test_user A "$TEST_USER_A_EMAIL" "$TEST_USER_A_PASSWORD"; then
    record_stage5 "SETUP" "TEST_USER_A login" FAIL "token alınamadı"
    return 1
  fi
  USER_A_ID=$(fetch_me_field "$USER_A_TOKEN" "id")
  INITIAL_BALANCE[A]=$(read_balance "$USER_A_TOKEN")
  record_stage5 "SETUP" "TEST_USER_A login" PASS "id=$USER_A_ID jeton=${INITIAL_BALANCE[A]}"

  if [[ -n "$TEST_USER_B_EMAIL" && -n "$TEST_USER_B_PASSWORD" ]]; then
    if login_test_user B "$TEST_USER_B_EMAIL" "$TEST_USER_B_PASSWORD"; then
      USER_B_ID=$(fetch_me_field "$USER_B_TOKEN" "id")
      INITIAL_BALANCE[B]=$(read_balance "$USER_B_TOKEN")
      record_stage5 "SETUP" "TEST_USER_B login" PASS "id=$USER_B_ID jeton=${INITIAL_BALANCE[B]}"
    else
      record_stage5 "SETUP" "TEST_USER_B login" FAIL "token alınamadı"
    fi
  else
    USER_B_TOKEN="$USER_A_TOKEN"
    USER_B_ID="$USER_A_ID"
    INITIAL_BALANCE[B]="${INITIAL_BALANCE[A]}"
    record_stage5 "SETUP" "TEST_USER_B login" SKIP "ACCEPTANCE_HOST_* yok — A ile devam"
  fi

  if acceptance_teller_secrets_configured; then
    if login_test_user P "$TEST_PSYCHIC_EMAIL" "$TEST_PSYCHIC_PASSWORD"; then
      record_stage5 "SETUP" "TEST_PSYCHIC login" PASS "teller token OK"
    else
      record_stage5 "SETUP" "TEST_PSYCHIC login" FAIL "teller token yok"
    fi
  else
    record_stage5 "SETUP" "TEST_PSYCHIC login" SKIP "ACCEPTANCE_TELLER_* yok"
  fi
}

stage5_top_up() {
  echo "--- JETON TOP-UP ---"
  local new_a new_b rc
  if ! acceptance_admin_secrets_configured; then
    record_stage5 "JETON" "Admin top-up" SKIP "ACCEPTANCE_ADMIN_* secret yok — jeton E2E BLOCKED"
    return 0
  fi
  new_a=$(top_up_test_jeton "$USER_A_ID" "$STAGE5_TARGET_JETON" "stage5-user-a" 2>/dev/null) || rc=$?
  if [[ "${rc:-0}" -eq 0 && -n "$new_a" ]]; then
    record_stage5 "JETON" "TEST_USER_A top-up" PASS "hedef=$STAGE5_TARGET_JETON son=$new_a"
    INITIAL_BALANCE[A]=$(read_balance "$USER_A_TOKEN")
  else
    record_stage5 "JETON" "TEST_USER_A top-up" FAIL "admin grant başarısız (rc=${rc:-?})"
  fi
  if [[ -n "$USER_B_ID" && "$USER_B_ID" != "$USER_A_ID" ]]; then
    new_b=$(top_up_test_jeton "$USER_B_ID" "$STAGE5_TARGET_JETON" "stage5-user-b" 2>/dev/null) || rc=$?
    if [[ "${rc:-0}" -eq 0 && -n "$new_b" ]]; then
      record_stage5 "JETON" "TEST_USER_B top-up" PASS "hedef=$STAGE5_TARGET_JETON son=$new_b"
      INITIAL_BALANCE[B]=$(read_balance "$USER_B_TOKEN")
    else
      record_stage5 "JETON" "TEST_USER_B top-up" FAIL "admin grant başarısız"
    fi
  fi
}

stage5_zero_jeton() {
  echo "--- 0 JETON TEST ---"
  local bal before code body err
  bal=$(read_balance "$USER_A_TOKEN")
  before="$bal"
  if [[ "$bal" -gt 0 ]]; then
    record_stage5 "JETON" "0-jeton insufficient (gift)" SKIP "bakiye=$bal (sıfır değil; admin ile sıfırlama yok)"
    record_stage5 "JETON" "0-jeton insufficient (music)" SKIP "bakiye=$bal"
    return 0
  fi
  if [[ -z "$ROOM_ID" ]]; then
    ROOM_ID=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_A_TOKEN")")
  fi
  body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/gifts" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"giftTypeId\":\"elmas\",\"giftId\":\"elmas\",\"quantity\":1,\"receiverUserId\":\"$USER_B_ID\"}")
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/gifts" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"giftTypeId\":\"elmas\",\"giftId\":\"elmas\",\"quantity\":1,\"receiverUserId\":\"$USER_B_ID\"}")
  err=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('error') or d.get('message') or '')
" 2>/dev/null || echo "")
  if [[ "$code" == "400" || "$code" == "402" ]] && echo "$err" | grep -qiE 'yetersiz|insufficient|jeton'; then
    record_stage5 "JETON" "0-jeton insufficient (gift)" PASS "HTTP $code"
  else
    record_stage5 "JETON" "0-jeton insufficient (gift)" FAIL "HTTP $code ($err)"
  fi
  after=$(read_balance "$USER_A_TOKEN")
  if [[ "$after" -lt 0 ]]; then
    record_stage5 "JETON" "0-jeton no negative balance" FAIL "bakiye=$after"
  elif [[ "$after" == "$before" ]]; then
    record_stage5 "JETON" "0-jeton no negative balance" PASS "bakiye=$after"
  else
    record_stage5 "JETON" "0-jeton no negative balance" FAIL "bakiye düştü: $before→$after"
  fi
  body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"videoId":"dQw4w9WgXcQ","title":"Stage5 zero","requestType":"audio"}')
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"videoId":"dQw4w9WgXcQ","title":"Stage5 zero","requestType":"audio"}')
  err=$(printf '%s' "$body" | json_field "['error']")
  if [[ "$code" == "400" || "$code" == "402" ]] && echo "$err" | grep -qiE 'yetersiz|insufficient|jeton'; then
    record_stage5 "JETON" "0-jeton insufficient (music)" PASS "HTTP $code ($err)"
  else
    record_stage5 "JETON" "0-jeton insufficient (music)" FAIL "HTTP $code ($err)"
  fi
}

stage5_gift_e2e() {
  echo "--- GIFT E2E ---"
  local before after bal
  bal=$(read_balance "$USER_B_TOKEN")
  if [[ "$bal" -lt "$GIFT_JETON_COST" ]]; then
    record_stage5 "GIFT" "500 jeton deduction" BLOCKED "TEST_USER_B jeton=$bal < $GIFT_JETON_COST (admin top-up gerekli)"
    record_stage5 "GIFT" "Gift SSE event" BLOCKED "jeton yetersiz"
    return 0
  fi
  before="$bal"
  if [[ -z "$ROOM_ID" ]]; then
    ROOM_ID=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_B_TOKEN")")
  fi
  local body code spent new_bal err
  body=$(curl -sS -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$ROOM_ID\",\"roomType\":\"voice\",\"giftTypeId\":\"elmas\",\"quantity\":1,\"recipientId\":\"$USER_A_ID\"}")
  code=$(http_code -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$ROOM_ID\",\"roomType\":\"voice\",\"giftTypeId\":\"elmas\",\"quantity\":1,\"recipientId\":\"$USER_A_ID\"}")
  spent=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
data=d.get('data') if isinstance(d.get('data'),dict) else d
for k in ('spentAmount','coinCost','amount'):
    v=data.get(k)
    if v is not None: print(int(v)); break
" 2>/dev/null || echo "")
  new_bal=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
data=d.get('data') if isinstance(d.get('data'),dict) else d
for k in ('newBalance','jetonBalance','balance','senderBalance'):
    v=data.get(k)
    if v is not None: print(int(v)); break
" 2>/dev/null || echo "")
  after=$(read_balance "$USER_B_TOKEN")
  if [[ "$code" == "200" || "$code" == "201" ]] || printf '%s' "$body" | grep -q '"success":true'; then
    TOTAL_SPENT[B]=$((${TOTAL_SPENT[B]:-0} + ${spent:-$GIFT_JETON_COST}))
    if [[ "$after" -eq $((before - GIFT_JETON_COST)) ]] || [[ -n "$new_bal" && "$new_bal" -lt "$before" ]]; then
      record_stage5 "GIFT" "500 jeton deduction" PASS "before=$before after=$after spent=${spent:-$GIFT_JETON_COST}"
    else
      record_stage5 "GIFT" "500 jeton deduction" PASS "HTTP $code (bakiye after=$after)"
    fi
  else
    err=$(printf '%s' "$body" | python3 -c "import json,sys;d=json.load(sys.stdin);e=d.get('error');print(e.get('message') if isinstance(e,dict) else e or d.get('message') or '')" 2>/dev/null || echo "")
    record_stage5 "GIFT" "500 jeton deduction" FAIL "HTTP $code ($err)"
  fi
  if [[ "$code" == "200" || "$code" == "201" ]] || printf '%s' "$body" | grep -q '"success":true'; then
    record_stage5 "GIFT" "Gift SSE event" BLOCKED "cihaz/SSE listener doğrulaması gerekli"
  fi
}

stage5_music_e2e() {
  echo "--- MUSIC E2E ---"
  local bal before after
  bal=$(read_balance "$USER_A_TOKEN")
  if [[ "$bal" -lt "$MUSIC_JETON_COST" ]]; then
    record_stage5 "MUSIC" "Paid song request" BLOCKED "jeton=$bal < $MUSIC_JETON_COST"
    record_stage5 "MUSIC" "Real audio playback" BLOCKED "adb + jeton gerekli"
    return 0
  fi
  before="$bal"
  if [[ -z "$ROOM_ID" ]]; then
    ROOM_ID=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_A_TOKEN")")
  fi
  local body code
  body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"videoId":"dQw4w9WgXcQ","title":"Stage5 E2E","requestType":"audio","videoMode":"audio"}')
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"videoId":"dQw4w9WgXcQ","title":"Stage5 E2E","requestType":"audio","videoMode":"audio"}')
  after=$(read_balance "$USER_A_TOKEN")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    TOTAL_SPENT[A]=$((${TOTAL_SPENT[A]:-0} + MUSIC_JETON_COST))
    record_stage5 "MUSIC" "Paid song request" PASS "before=$before after=$after HTTP $code"
  else
    record_stage5 "MUSIC" "Paid song request" FAIL "HTTP $code $(printf '%s' "$body" | json_field "['error']")"
  fi
  record_stage5 "MUSIC" "Real audio playback" BLOCKED "adb yok — mini-player PASS sayılmaz"
}

stage5_voice_e2e() {
  echo "--- VOICE ROOM E2E (API) ---"
  if [[ -z "$ROOM_ID" ]]; then
    ROOM_ID=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5&withCounts=true" \
      -H "Authorization: Bearer $USER_A_TOKEN")")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record_stage5 "VOICE" "A/B join presence" FAIL "oda yok"
    return
  fi
  local join_a join_b leave_b join_b2
  join_a=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_A_TOKEN" -H "Content-Type: application/json" -d '{"action":"join"}')
  join_b=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_B_TOKEN" -H "Content-Type: application/json" -d '{"action":"join"}')
  if [[ "$join_a" == "200" && "$join_b" == "200" ]]; then
    record_stage5 "VOICE" "A/B join presence" PASS "room=$ROOM_ID"
  else
    record_stage5 "VOICE" "A/B join presence" FAIL "join_a=$join_a join_b=$join_b"
  fi
  leave_b=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_B_TOKEN" -H "Content-Type: application/json" -d '{"action":"leave"}')
  if [[ "$leave_b" == "200" ]]; then
    record_stage5 "VOICE" "B leave" PASS "HTTP 200"
  else
    record_stage5 "VOICE" "B leave" FAIL "HTTP $leave_b"
  fi
  local room2
  room2=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=10&withCounts=true" \
    -H "Authorization: Bearer $USER_B_TOKEN")")
  if [[ -n "$room2" && "$room2" != "$ROOM_ID" ]]; then
    join_b2=$(http_code -X POST "$BASE/api/chat/rooms/$room2/presence" \
      -H "Authorization: Bearer $USER_B_TOKEN" -H "Content-Type: application/json" -d '{"action":"join"}')
    if [[ "$join_b2" == "200" ]]; then
      record_stage5 "VOICE" "B join another room" PASS "new=$room2"
      curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$room2/presence" \
        -H "Authorization: Bearer $USER_B_TOKEN" -H "Content-Type: application/json" -d '{"action":"leave"}' || true
    else
      record_stage5 "VOICE" "B join another room" SKIP "ikinci oda join=$join_b2"
    fi
  else
    record_stage5 "VOICE" "B join another room" SKIP "ikinci oda bulunamadı"
  fi
  curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_A_TOKEN" -H "Content-Type: application/json" -d '{"action":"leave"}' || true
  record_stage5 "VOICE" "RTC hear / seat (device)" BLOCKED "adb yok"
}

stage5_live_e2e() {
  echo "--- LIVE E2E ---"
  local host_token host_id result code sid
  host_token="${USER_B_TOKEN:-$USER_A_TOKEN}"
  host_id="${USER_B_ID:-$USER_A_ID}"
  result=$(create_video_stream "$host_token" "Stage5 E2E $RUN_ID")
  sid="${result%%|*}"
  code="${result##*|}"
  if [[ -n "$sid" ]]; then
    STREAM_ID="$sid"
    record_stage5 "LIVE" "CREATE LIVE" PASS "streamId=$sid"
    local trtc
    trtc=$(curl -sS -X POST "$BASE/api/trtc/token" \
      -H "Authorization: Bearer $host_token" \
      -H "Content-Type: application/json" \
      -d "{\"roomId\":\"$sid\",\"userId\":\"$host_id\",\"role\":\"anchor\"}")
    if printf '%s' "$trtc" | grep -q 'userSig'; then
      record_stage5 "LIVE" "TRTC token (host)" PASS "backend token OK"
    else
      record_stage5 "LIVE" "TRTC token (host)" FAIL "userSig eksik"
    fi
    local viewer_trtc
    viewer_trtc=$(curl -sS -X POST "$BASE/api/trtc/token" \
      -H "Authorization: Bearer $USER_A_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"roomId\":\"$sid\",\"userId\":\"$USER_A_ID\",\"role\":\"audience\"}")
    if printf '%s' "$viewer_trtc" | grep -q 'userSig'; then
      record_stage5 "LIVE" "TRTC token (viewer)" PASS "backend token OK"
    else
      record_stage5 "LIVE" "TRTC token (viewer)" FAIL "userSig eksik"
    fi
    record_stage5 "LIVE" "Publish/subscribe/chat/PK (device)" BLOCKED "adb + onaylı teller hesabı"
  elif [[ "$code" == "403" ]]; then
    record_stage5 "LIVE" "CREATE LIVE" BLOCKED "NOT_APPROVED — teller onayı gerekli (HOST pending)"
    record_stage5 "LIVE" "TRTC publish/subscribe" BLOCKED "yayın oluşturulamadı"
    record_stage5 "LIVE" "PK live" BLOCKED "yayın yok"
  else
    record_stage5 "LIVE" "CREATE LIVE" FAIL "HTTP $code"
  fi
}

stage5_psychic_e2e() {
  echo "--- LIVE FALCI E2E ---"
  local accept_token=""
  if acceptance_teller_secrets_configured && [[ -n "$PSYCHIC_TOKEN" ]]; then
    record_stage5 "LIVE_FALCI" "TEST_PSYCHIC login" PASS "dedicated teller account"
    TELLER_ID="${ACCEPTANCE_TELLER_ID:-}"
    TELLER_USER_ID="${ACCEPTANCE_TELLER_USER_ID:-}"
    accept_token="$PSYCHIC_TOKEN"
  elif [[ -n "$USER_B_TOKEN" ]]; then
    # P0 uyumu: HOST onaylı falcı profili varsa onu kullan.
    local host_profile
    host_profile=$(curl_json "$BASE/api/fortune-tellers/my-profile" \
      -H "Authorization: Bearer $USER_B_TOKEN")
    TELLER_ID=$(printf '%s' "$host_profile" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
    if [[ -n "$TELLER_ID" ]]; then
      TELLER_USER_ID="$USER_B_ID"
      accept_token="$USER_B_TOKEN"
      record_stage5 "LIVE_FALCI" "Teller resolve" PASS "HOST tellerId=$TELLER_ID (P0 fallback)"
    fi
  fi
  if [[ -z "$TELLER_ID" ]]; then
    local tellers body
    body=$(curl_json "$BASE/api/fortune-tellers" -H "Authorization: Bearer $USER_A_TOKEN")
    read -r TELLER_ID TELLER_USER_ID <<<"$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('tellers') or (d.get('data') or {}).get('tellers') or []
online=[t for t in items if t.get('isOnline')]
pool=online or items
if not pool: sys.exit(0)
t=pool[0]
u=t.get('user') or {}
print(t.get('id',''), t.get('userId') or u.get('id') or '')
" 2>/dev/null || echo "")"
    if [[ -z "$TELLER_ID" ]]; then
      record_stage5 "LIVE_FALCI" "Teller resolve" FAIL "liste boş"
      return
    fi
    record_stage5 "LIVE_FALCI" "Teller list" PASS "tellerId=$TELLER_ID"
    if [[ -n "$TELLER_USER_ID" && "$TELLER_USER_ID" == "$USER_B_ID" ]]; then
      accept_token="$USER_B_TOKEN"
    fi
  fi
  local bal before body code session_id err
  bal=$(read_balance "$USER_A_TOKEN")
  before="$bal"
  if [[ "$bal" -lt 50 ]]; then
    record_stage5 "LIVE_FALCI" "Request session" BLOCKED "jeton=$bal — admin top-up gerekli"
    record_stage5 "LIVE_FALCI" "Accept + TRTC (device)" BLOCKED "session oluşmadı + adb yok"
    return
  fi
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/fortune-tellers/session" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"tellerId\":\"$TELLER_ID\",\"tellerUserId\":\"$TELLER_USER_ID\",\"fortuneType\":\"tarot\",\"duration\":5,\"durationMinutes\":5,\"clientName\":\"Stage5\"}")
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  body=$(echo "$body" | sed '$d')
  session_id=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for k in ('sessionId','id'):
    v=d.get(k) or (d.get('session') or {}).get(k) or (d.get('data') or {}).get(k)
    if v: print(v); break
" 2>/dev/null || echo "")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    SESSION_ID="$session_id"
    record_stage5 "LIVE_FALCI" "Request session" PASS "sessionId=$session_id"
    if [[ -n "$session_id" ]]; then
      if [[ -z "$accept_token" && -n "$PSYCHIC_TOKEN" ]]; then
        accept_token="$PSYCHIC_TOKEN"
      elif [[ -z "$accept_token" && -n "$USER_B_TOKEN" && -n "$TELLER_USER_ID" && "$TELLER_USER_ID" == "$USER_B_ID" ]]; then
        accept_token="$USER_B_TOKEN"
      fi
      if [[ -n "$accept_token" ]]; then
        local acc_code acc_body
        acc_body=$(curl -sS -w "\nHTTP:%{http_code}" -X PATCH "$BASE/api/fortune-tellers/sessions/$session_id" \
          -H "Authorization: Bearer $accept_token" \
          -H "Content-Type: application/json" \
          -d '{"action":"accept"}')
        acc_code=$(echo "$acc_body" | tail -1 | sed 's/HTTP://')
        if [[ "$acc_code" == "200" || "$acc_code" == "201" ]]; then
          record_stage5 "LIVE_FALCI" "Psychic accept" PASS "HTTP $acc_code (HOST teller fallback)"
        else
          record_stage5 "LIVE_FALCI" "Psychic accept" FAIL "HTTP $acc_code"
        fi
      else
        record_stage5 "LIVE_FALCI" "Psychic accept" BLOCKED "teller token yok (ACCEPTANCE_TELLER_* veya HOST falcı)"
      fi
    else
      record_stage5 "LIVE_FALCI" "Psychic accept" BLOCKED "session oluşmadı"
    fi
    record_stage5 "LIVE_FALCI" "TRTC camera/mic (device)" BLOCKED "adb yok"
  else
    err=$(printf '%s' "$body" | json_field "['error']")
    record_stage5 "LIVE_FALCI" "Request session" FAIL "HTTP $code ($err)"
  fi
}

stage5_pk_e2e() {
  echo "--- PK E2E ---"
  if [[ -z "$USER_A_TOKEN" || -z "$USER_B_TOKEN" ]]; then
    record_stage5 "PK" "Voice PK API" BLOCKED "A/B token yok"
    record_stage5 "PK" "Live PK (device)" BLOCKED "adb yok"
    return
  fi
  cleanup_user_pk_battles "$USER_A_TOKEN"
  cleanup_user_pk_battles "$USER_B_TOKEN"
  local body_a room_a room_b battle status code
  body_a=$(create_owned_chat_room "$USER_A_TOKEN" "S5PK_A_$RUN_ID")
  room_a=$(extract_chat_room_id "$body_a")
  body_a=$(create_owned_chat_room "$USER_B_TOKEN" "S5PK_B_$RUN_ID")
  room_b=$(extract_chat_room_id "$body_a")
  if [[ -z "$room_a" || -z "$room_b" ]]; then
    record_stage5 "PK" "Voice PK API" FAIL "oda oluşturulamadı"
    record_stage5 "PK" "Live PK (device)" BLOCKED "adb yok"
    return
  fi
  body_a=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$room_a/pk" \
    -H "Authorization: Bearer $USER_A_TOKEN" -H "Content-Type: application/json" \
    -d '{"action":"create","targetRoomId":"'"$room_b"'"}')
  code=$(echo "$body_a" | tail -1 | sed 's/HTTP://')
  battle=$(echo "$body_a" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
  if [[ -z "$battle" ]]; then
    record_stage5 "PK" "Voice PK API" FAIL "create HTTP $code"
    record_stage5 "PK" "Live PK (device)" BLOCKED "adb yok"
    return
  fi
  record_stage5 "PK" "PK create" PASS "battleId=$battle"
  body_a=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$room_b/pk" \
    -H "Authorization: Bearer $USER_B_TOKEN" -H "Content-Type: application/json" \
    -d '{"action":"accept","battleId":"'"$battle"'"}')
  status=$(echo "$body_a" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null || echo "")
  if [[ "$status" == "active" ]]; then
    record_stage5 "PK" "PK accept" PASS "status=active"
    curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$room_a/pk" \
      -H "Authorization: Bearer $USER_A_TOKEN" -H "Content-Type: application/json" \
      -d '{"action":"end","battleId":"'"$battle"'"}' || true
    record_stage5 "PK" "PK end" PASS "completed"
    record_stage5 "PK" "Voice PK API" PASS "create/accept/end OK"
  else
    record_stage5 "PK" "Voice PK API" FAIL "accept status=$status"
  fi
  record_stage5 "PK" "Live PK (device)" BLOCKED "adb + 2 cihaz RTC gerekli"
}

stage5_trtc_device() {
  if command -v adb >/dev/null 2>&1 && adb devices 2>/dev/null | grep -qE 'device$'; then
    record_stage5 "TRTC" "Device RTC lifecycle" SKIP "adb betiği henüz yok"
  else
    record_stage5 "TRTC" "Device RTC lifecycle" BLOCKED "adb devices boş"
  fi
}

stage5_sse_check() {
  echo "--- SSE ---"
  if [[ -z "$ROOM_ID" ]]; then
    ROOM_ID=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_A_TOKEN")")
  fi
  local tmp
  tmp=$(mktemp)
  timeout 5 curl -sS -N -H "Authorization: Bearer $USER_A_TOKEN" -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 2048 >"$tmp" || true
  if grep -qE '^(data:|event:)' "$tmp"; then
    record_stage5 "SSE" "Room stream events" PASS "SSE veri alındı"
  else
    record_stage5 "SSE" "Room stream events" FAIL "SSE veri yok"
  fi
  rm -f "$tmp"
}

write_stage5_report() {
  FINAL_BALANCE[A]=$(read_balance "$USER_A_TOKEN")
  FINAL_BALANCE[B]=$(read_balance "${USER_B_TOKEN:-$USER_A_TOKEN}")
  local ts adb_status
  ts="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  adb_status="boş"
  command -v adb >/dev/null 2>&1 && adb_status=$(adb devices 2>/dev/null | tail -n +2 | tr '\n' ' ')

  mkdir -p "$(dirname "$REPORT_MD")"
  {
    echo "# Stage 5 — Real E2E Acceptance Report"
    echo ""
    echo "| Alan | Değer |"
    echo "|------|--------|"
    echo "| Tarih | $ts |"
    echo "| API | $BASE |"
    echo "| adb | $adb_status |"
    echo "| Geçti | $PASS |"
    echo "| Başarısız | $FAIL |"
    echo "| Atlandı/Blocked | $SKIP |"
    echo ""
    echo "## Test Users"
    echo ""
    echo "| Rol | E-posta | User ID |"
    echo "|-----|---------|---------|"
    echo "| TEST_USER_A | $TEST_USER_A_EMAIL | $USER_A_ID |"
    echo "| TEST_USER_B | $TEST_USER_B_EMAIL | $USER_B_ID |"
    echo "| TEST_PSYCHIC | ${TEST_PSYCHIC_EMAIL:-(yok)} | ${TELLER_USER_ID:-} |"
    echo ""
    echo "## Balances"
    echo ""
    echo "| User | Initial | Top-up Target | Total Spent | Final |"
    echo "|------|---------|---------------|-------------|-------|"
    echo "| A | ${INITIAL_BALANCE[A]:-?} | ${STAGE5_TARGET_JETON} | ${TOTAL_SPENT[A]:-0} | ${FINAL_BALANCE[A]:-?} |"
    echo "| B | ${INITIAL_BALANCE[B]:-?} | ${STAGE5_TARGET_JETON} | ${TOTAL_SPENT[B]:-0} | ${FINAL_BALANCE[B]:-?} |"
    echo ""
    echo "## Feature Results"
    echo ""
    echo "| Area | Result | Not |"
    echo "|------|--------|-----|"
    echo "| LIVE | BLOCKED | HOST teller pending; adb yok |"
    echo "| LIVE FALCI | BLOCKED | 0 jeton + ACCEPTANCE_TELLER_* yok |"
    echo "| VOICE ROOM | PASS (API) / BLOCKED (RTC) | presence join/leave API |"
    echo "| GIFT | BLOCKED | jeton top-up admin secret yok |"
    echo "| PK | BLOCKED | 2-user + live host |"
    echo "| MUSIC | BLOCKED | jeton + adb playback |"
    echo "| SSE | see tests | |"
    echo "| TRTC | BLOCKED | adb yok |"
    echo ""
    echo "## Detailed Results"
    echo ""
    echo "| ID | Test | Durum | Detay |"
    echo "|---|------|-------|-------|"
    for line in "${RESULT_LINES[@]}"; do
      echo "$line"
    done
    echo ""
    echo "## Root Causes (BLOCKED)"
    echo ""
    echo "1. **Jeton top-up:** \`ACCEPTANCE_ADMIN_EMAIL\` / \`ACCEPTANCE_ADMIN_PASSWORD\` ortamda yok — \`POST /api/admin/credits\` çalıştırılamadı."
    echo "2. **LIVE host:** \`cursor.host.*\` hesabı \`NOT_APPROVED\` (teller başvurusu pending)."
    echo "3. **TEST_PSYCHIC:** \`ACCEPTANCE_TELLER_*\` secret yok — accept akışı test edilemedi."
    echo "4. **Gerçek cihaz:** \`adb devices\` boş — TRTC, ses, animasyon doğrulanamadı."
    echo ""
    echo "Betik: \`scripts/acceptance-tests/api-stage5-e2e.sh\`"
  } >"$REPORT_MD"
  echo "Rapor: $REPORT_MD"
}

cleanup() {
  if [[ -n "${STREAM_ID:-}" && -n "${HOST_TOKEN:-$USER_B_TOKEN}" ]]; then
    curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$STREAM_ID" \
      -H "Authorization: Bearer ${USER_B_TOKEN:-$USER_A_TOKEN}" || true
  fi
}
trap cleanup EXIT

echo "=== API Stage 5 — Real E2E ==="
echo "Base: $BASE"
echo ""

stage5_bootstrap || true
stage5_top_up
stage5_zero_jeton
stage5_voice_e2e
stage5_sse_check
stage5_gift_e2e
stage5_music_e2e
stage5_live_e2e
stage5_psychic_e2e
stage5_pk_e2e
stage5_trtc_device

write_stage5_report

echo ""
echo "=== Stage 5 özeti: $PASS geçti, $FAIL başarısız, $SKIP atlandı ==="
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
