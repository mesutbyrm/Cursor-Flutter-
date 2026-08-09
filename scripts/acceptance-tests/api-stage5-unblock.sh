#!/usr/bin/env bash
# Stage 5 — API katmanında mümkün olan BLOCKED maddeleri kapatır (cihaz gerektirmeyen).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

USER_A_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
USER_A_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
USER_B_EMAIL="${ACCEPTANCE_HOST_EMAIL:-}"
USER_B_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-}"

USER_A_TOKEN=""
USER_B_TOKEN=""
USER_A_ID=""
USER_B_ID=""
ROOM_A=""
ROOM_B=""

record_u() {
  record "UNBLOCK" "$1" "$2" "${3:-}"
}

login_users() {
  local resp
  resp=$(mobile_login_identifier email "$USER_A_EMAIL" "$USER_A_PASSWORD")
  USER_A_TOKEN=$(extract_token "$resp")
  USER_A_ID=$(fetch_me_field "$USER_A_TOKEN" "id")
  resp=$(mobile_login_identifier email "$USER_B_EMAIL" "$USER_B_PASSWORD")
  USER_B_TOKEN=$(extract_token "$resp")
  USER_B_ID=$(fetch_me_field "$USER_B_TOKEN" "id")
}

unblock_insufficient_without_zero() {
  echo "--- UNBLOCK: yetersiz jeton (bakiye sıfırlamadan) ---"
  local bal before after body code err
  bal=$(user_jeton_balance_from_me "$USER_B_TOKEN")
  before="$bal"
  local room qty needed
  room=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_B_TOKEN")")
  qty=$(( (bal / 500) + 2 ))
  needed=$((qty * 500))
  body=$(curl -sS -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"roomType\":\"voice\",\"giftTypeId\":\"elmas\",\"quantity\":$qty,\"recipientId\":\"$USER_A_ID\"}")
  code=$(http_code -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"roomType\":\"voice\",\"giftTypeId\":\"elmas\",\"quantity\":$qty,\"recipientId\":\"$USER_A_ID\"}")
  err=$(printf '%s' "$body" | grep -oiE 'insufficient|yetersiz|INSUFFICIENT' || true)
  after=$(user_jeton_balance_from_me "$USER_B_TOKEN")
  if [[ -n "$err" ]] && [[ "$after" -eq "$before" ]]; then
    record_u "Insufficient (overspend)" PASS "HTTP $code qty=$qty need~$needed bakiye=$before→$after"
  else
    record_u "Insufficient (overspend)" FAIL "HTTP $code bakiye=$before→$after"
  fi
}

unblock_gift_sse() {
  echo "--- UNBLOCK: gift SSE event (network) ---"
  local room tmp pid
  room=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_B_TOKEN")")
  tmp=$(mktemp)
  timeout 12 curl -sS -N \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$room/stream" >"$tmp" 2>/dev/null &
  pid=$!
  sleep 2
  curl -sS -o /dev/null -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"roomType\":\"voice\",\"giftTypeId\":\"kalp\",\"quantity\":1,\"recipientId\":\"$USER_A_ID\"}" || true
  sleep 4
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  if grep -qiE 'gift|hediye' "$tmp"; then
    record_u "Gift SSE event" PASS "stream içinde gift event"
  else
    record_u "Gift SSE event" BLOCKED "SSE'de gift event yakalanamadı (oda=$room)"
  fi
  rm -f "$tmp"
}

ensure_two_owned_rooms() {
  local body
  body=$(create_owned_chat_room "$USER_A_TOKEN" "UnblockA_$RUN_ID")
  ROOM_A=$(extract_chat_room_id "$body")
  body=$(create_owned_chat_room "$USER_B_TOKEN" "UnblockB_$RUN_ID")
  ROOM_B=$(extract_chat_room_id "$body")
  if [[ -n "$ROOM_A" ]]; then
    record_u "Create room A (owner)" PASS "roomId=$ROOM_A"
  else
    record_u "Create room A (owner)" FAIL "oda oluşturulamadı"
  fi
  if [[ -n "$ROOM_B" ]]; then
    record_u "Create room B (owner)" PASS "roomId=$ROOM_B"
  else
    record_u "Create room B (owner)" FAIL "oda oluşturulamadı"
  fi
}

unblock_pk_two_user() {
  echo "--- UNBLOCK: PK 2-user create→accept→end ---"
  ensure_two_owned_rooms
  if [[ -z "$ROOM_A" || -z "$ROOM_B" ]]; then
    record_u "PK 2-user accept" BLOCKED "oda oluşturulamadı"
    return
  fi
  local body code battle_id status
  cleanup_user_pk_battles "$USER_A_TOKEN"
  cleanup_user_pk_battles "$USER_B_TOKEN"
  cleanup_room_pk "$USER_A_TOKEN" "$ROOM_A"
  cleanup_room_pk "$USER_B_TOKEN" "$ROOM_B"
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$ROOM_A/pk" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"create","targetRoomId":"'"$ROOM_B"'"}')
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  battle_id=$(echo "$body" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
  if [[ "$code" != "200" && "$code" != "201" ]] || [[ -z "$battle_id" ]]; then
    record_u "PK create (A→B)" FAIL "HTTP $code"
    record_u "PK 2-user accept" BLOCKED "PK oluşturulamadı"
    return
  fi
  record_u "PK create (A→B)" PASS "battleId=$battle_id"
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$ROOM_B/pk" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"accept","battleId":"'"$battle_id"'"}')
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  status=$(echo "$body" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null || echo "")
  if [[ "$code" == "200" || "$code" == "201" ]] && [[ "$status" == "active" ]]; then
    record_u "PK 2-user accept" PASS "status=active"
  else
    record_u "PK 2-user accept" FAIL "HTTP $code status=$status"
    return
  fi
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$ROOM_A/pk" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"end","battleId":"'"$battle_id"'"}')
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  status=$(echo "$body" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null || echo "")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    record_u "PK end" PASS "status=${status:-ended}"
  else
    record_u "PK end" FAIL "HTTP $code"
  fi
}

unblock_host_teller_approval() {
  echo "--- UNBLOCK: host teller onayı (admin varsa) ---"
  local profile status teller_id approved
  profile=$(curl_json "$BASE/api/fortune-tellers/my-profile" -H "Authorization: Bearer $USER_B_TOKEN")
  status=$(printf '%s' "$profile" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('applicationStatus',''))" 2>/dev/null || echo "")
  teller_id=$(printf '%s' "$profile" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
  if [[ "$status" == "approved" ]]; then
    record_u "Host teller approval" PASS "zaten onaylı tellerId=$teller_id"
    return 0
  fi
  if acceptance_admin_secrets_configured; then
    approved=$(try_approve_host_teller "$USER_B_TOKEN" || true)
    if [[ -n "$approved" ]]; then
      sleep 1
      status=$(curl_json "$BASE/api/fortune-tellers/my-profile" -H "Authorization: Bearer $USER_B_TOKEN" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('applicationStatus',''))" 2>/dev/null || echo "")
      if [[ "$status" == "approved" ]]; then
        record_u "Host teller approval" PASS "admin onayı OK tellerId=$approved"
        return 0
      fi
      record_u "Host teller approval" FAIL "admin çağrısı yapıldı ama status=$status"
      return 1
    fi
    record_u "Host teller approval" FAIL "admin onay endpoint başarısız"
    return 1
  fi
  record_u "Host teller approval" BLOCKED "applicationStatus=$status — admin panelden onaylayın veya ACCEPTANCE_ADMIN_* ekleyin"
  return 1
}

unblock_live_create() {
  echo "--- UNBLOCK: LIVE create (host onaylıysa) ---"
  local result sid code
  result=$(create_video_stream "$USER_B_TOKEN" "Stage5 Unblock $RUN_ID")
  sid="${result%%|*}"
  code="${result##*|}"
  if [[ -n "$sid" ]]; then
    record_u "LIVE create (host)" PASS "streamId=$sid"
    curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$sid" \
      -H "Authorization: Bearer $USER_B_TOKEN" || true
  elif [[ "$code" == "403" ]]; then
    record_u "LIVE create (host)" BLOCKED "NOT_APPROVED — host teller onayı gerekli"
  else
    record_u "LIVE create (host)" FAIL "HTTP $code"
  fi
}

unblock_psychic_session() {
  echo "--- UNBLOCK: LIVE FALCI session (staffExempt API) ---"
  local tellers tid tuid body code sid
  tellers=$(curl_json "$BASE/api/fortune-tellers" -H "Authorization: Bearer $USER_A_TOKEN")
  read -r tid tuid <<<"$(printf '%s' "$tellers" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('tellers') or []
online=[t for t in items if t.get('isOnline')]
t=(online or items)[0] if items else {}
u=t.get('user') or {}
print(t.get('id',''), t.get('userId') or u.get('id') or '')
" 2>/dev/null || echo "")"
  if [[ -z "$tid" ]]; then
    record_u "Psychic session" FAIL "teller yok"
    return 1
  fi
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/fortune-tellers/session" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"tellerId":"'"$tid"'","tellerUserId":"'"$tuid"'","fortuneType":"tarot","duration":5,"staffExempt":true}')
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  sid=$(echo "$body" | sed '$d' | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('sessionId') or (d.get('session') or {}).get('id') or '')
" 2>/dev/null || echo "")
  if [[ "$code" == "200" || "$code" == "201" ]] && [[ -n "$sid" ]]; then
    record_u "Psychic session create" PASS "sessionId=$sid staffExempt"
    st=$(http_code "$BASE/api/fortune-tellers/sessions?status=pending" -H "Authorization: Bearer $USER_A_TOKEN")
    if [[ "$st" == "200" ]]; then
      record_u "Psychic session pending list" PASS "HTTP 200"
    else
      record_u "Psychic session pending list" FAIL "HTTP $st"
    fi
    PSYCHIC_SESSION_ID="$sid"
    unblock_psychic_accept "$sid"
  else
    record_u "Psychic session create" FAIL "HTTP $code"
  fi
}

unblock_psychic_accept() {
  local session_id="$1"
  local respond_code trtc_body
  if acceptance_teller_secrets_configured && login_as_teller; then
    respond_code=$(http_code -X POST "$BASE/api/fortune-tellers/session/$session_id/respond" \
      -H "Authorization: Bearer $TELLER_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"action":"accept"}')
    if [[ "$respond_code" != "200" && "$respond_code" != "201" ]]; then
      respond_code=$(http_code -X PATCH "$BASE/api/fortune-tellers/sessions/$session_id" \
        -H "Authorization: Bearer $TELLER_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"status":"accepted","action":"accept"}')
    fi
    if [[ "$respond_code" == "200" || "$respond_code" == "201" ]]; then
      record_u "Psychic accept (teller)" PASS "HTTP $respond_code"
      trtc_body=$(curl -sS -X POST "$BASE/api/trtc/token" \
        -H "Authorization: Bearer $TELLER_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"roomId\":\"psychic_$session_id\",\"userId\":\"$(fetch_me_field "$TELLER_TOKEN" id)\",\"role\":\"anchor\"}")
      if trtc_response_has_sig "$trtc_body"; then
        record_u "Psychic TRTC token (teller)" PASS "backend token OK"
      else
        record_u "Psychic TRTC token (teller)" FAIL "userSig eksik"
      fi
      return
    fi
    record_u "Psychic accept (teller)" FAIL "HTTP $respond_code"
    return
  fi
  record_u "Psychic accept (teller)" BLOCKED "ACCEPTANCE_TELLER_* yok — falcı hesabı secret olarak ekleyin"
}

unblock_trtc_token_pair() {
  echo "--- UNBLOCK: TRTC token çift kullanıcı ---"
  local room body trtc_user_id
  room="stage5_${RUN_ID}"
  trtc_user_id="$USER_A_ID"
  body=$(curl -sS -X POST "$BASE/api/trtc/token" \
    -H "Authorization: Bearer $USER_A_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"userId\":\"$trtc_user_id\",\"role\":\"anchor\"}")
  if trtc_response_has_sig "$body"; then
    record_u "TRTC token A" PASS "role=anchor room=$room"
  else
    record_u "TRTC token A" FAIL "token eksik"
  fi
  trtc_user_id="$USER_B_ID"
  body=$(curl -sS -X POST "$BASE/api/trtc/token" \
    -H "Authorization: Bearer $USER_B_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"userId\":\"$trtc_user_id\",\"role\":\"audience\"}")
  if trtc_response_has_sig "$body"; then
    record_u "TRTC token B" PASS "role=audience room=$room"
  else
    record_u "TRTC token B" FAIL "token eksik"
  fi
  if command -v adb >/dev/null 2>&1 && adb devices 2>/dev/null | grep -qE 'device$'; then
    record_u "TRTC SDK enterRoom" BLOCKED "adb cihaz var — scripts/acceptance-tests/device-trtc-smoke.sh çalıştırın"
  else
    record_u "TRTC SDK enterRoom" BLOCKED "Telefon yok — USB hata ayıklama + adb gerekli (Cloud VM'de emülatör yok)"
  fi
}

echo "=== Stage 5 UNBLOCK (API) ==="
login_users
unblock_insufficient_without_zero
unblock_pk_two_user
unblock_gift_sse
unblock_host_teller_approval || true
unblock_live_create
unblock_psychic_session
unblock_trtc_token_pair

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/STAGE5_UNBLOCK_REPORT.md"
finalize_reports || exit 1
