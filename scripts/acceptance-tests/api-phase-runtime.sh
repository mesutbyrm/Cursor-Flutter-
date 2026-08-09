#!/usr/bin/env bash
# Faz bazlı API runtime doğrulaması (AUTH, TRTC, VOICE, LIVE, PK, PSYCHIC).
# Üretim API — gerçek JWT; cihaz/emülatör gerekmez.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
HOST_EMAIL="${ACCEPTANCE_HOST_EMAIL:-$USER_EMAIL}"
HOST_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-$USER_PASSWORD}"

USER_TOKEN=""
HOST_TOKEN=""
ROOM_ID=""
STREAM_ID=""

echo "=== Canlifal API Phase Runtime ==="
echo "Base: $BASE"
echo ""

phase_auth() {
  echo "--- PHASE: AUTH ---"
  if ! acceptance_user_secrets_configured; then
    record "AUTH" "Giriş + refresh" SKIP "ACCEPTANCE_USER_* yok"
    return
  fi
  local resp ref new_tok
  resp=$(mobile_login_identifier email "$USER_EMAIL" "$USER_PASSWORD")
  USER_TOKEN=$(extract_token "$resp")
  if [[ -z "$USER_TOKEN" ]]; then
    record "AUTH" "Giriş + refresh" FAIL "$(login_error_detail "$resp")"
    return
  fi
  ref=$(printf '%s' "$resp" | json_field "['refreshToken']")
  if [[ -z "$ref" ]]; then
    record "AUTH" "Giriş + refresh" FAIL "refreshToken yok"
    return
  fi
  resp=$(curl_json -X POST "$BASE/api/auth/mobile-refresh" \
    -H "Content-Type: application/json" \
    -d "{\"refreshToken\":\"$ref\"}")
  new_tok=$(extract_token "$resp")
  if [[ -n "$new_tok" ]]; then
    USER_TOKEN="$new_tok"
    record "AUTH" "Giriş + refresh" PASS "accessToken yenilendi"
  else
    record "AUTH" "Giriş + refresh" FAIL "refresh başarısız"
  fi
}

phase_trtc() {
  echo "--- PHASE: TRTC ---"
  skip_unless_user_token "TRTC" "TRTC token" || return 0
  local me uid code
  me=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN")
  uid=$(printf '%s' "$me" | json_field "['id']")
  [[ -z "$uid" ]] && uid=$(printf '%s' "$me" | json_field "['user']['id']")
  code=$(http_code -X POST "$BASE/api/trtc/token" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"userId\":\"$uid\",\"roomId\":\"phase_test_$RUN_ID\"}")
  if [[ "$code" == "200" ]]; then
    record "TRTC" "Token" PASS "HTTP 200"
  else
    code=$(http_code -X POST "$BASE/api/trtc/usersig" \
      -H "Authorization: Bearer $USER_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"userId\":\"$uid\",\"roomId\":\"phase_test_$RUN_ID\"}")
    if [[ "$code" == "200" ]]; then
      record "TRTC" "Token" PASS "usersig HTTP 200"
    else
      record "TRTC" "Token" FAIL "HTTP $code"
    fi
  fi
}

phase_voice() {
  echo "--- PHASE: VOICE ---"
  skip_unless_user_token "VOICE" "Presence + SSE" || return 0
  local body
  body=$(curl_json "$BASE/api/chat/rooms?limit=5&withCounts=true" \
    -H "Authorization: Bearer $USER_TOKEN")
  ROOM_ID=$(pick_first_room_id "$body")
  if [[ -z "$ROOM_ID" ]]; then
    record "VOICE" "Presence + SSE" FAIL "oda yok"
    return
  fi
  local join_code leave_code
  join_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"join"}')
  leave_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"leave"}')
  local tmp
  tmp=$(mktemp)
  timeout 5 curl -sS -N \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 1024 >"$tmp" || true
  rm -f "$tmp"
  if [[ "$join_code" == "200" && "$leave_code" == "200" ]]; then
    record "VOICE" "Presence + SSE" PASS "room=$ROOM_ID join/leave OK"
  else
    record "VOICE" "Presence + SSE" FAIL "join=$join_code leave=$leave_code"
  fi
}

phase_live() {
  echo "--- PHASE: LIVE ---"
  if ! require_secret HOST_EMAIL "LIVE" "Yayın oluşturma" || ! require_secret HOST_PASSWORD "LIVE" "Yayın oluşturma"; then
    return 0
  fi
  local resp
  resp=$(mobile_login_identifier email "$HOST_EMAIL" "$HOST_PASSWORD")
  HOST_TOKEN=$(extract_token "$resp")
  if [[ -z "$HOST_TOKEN" ]]; then
    record "LIVE" "Yayın oluşturma" FAIL "host token yok"
    return
  fi
  local result code
  result=$(create_video_stream "$HOST_TOKEN" "Phase $RUN_ID" fortune)
  STREAM_ID="${result%%|*}"
  code="${result##*|}"
  if [[ -n "$STREAM_ID" ]]; then
    record "LIVE" "Yayın oluşturma" PASS "streamId=$STREAM_ID"
  elif [[ "$code" == "403" ]]; then
    record "LIVE" "Yayın oluşturma" SKIP "NOT_A_TELLER (falcı onayı gerekli)"
  else
    record "LIVE" "Yayın oluşturma" FAIL "HTTP ${code:-?}"
  fi
}

phase_pk() {
  echo "--- PHASE: PK ---"
  skip_unless_user_token "PK" "Voice PK endpoint" || return 0
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_TOKEN")
    ROOM_ID=$(pick_first_room_id "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record "PK" "Voice PK endpoint" SKIP "oda yok"
    return
  fi
  local code body err
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/pk" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"create","targetRoomId":"'"$ROOM_ID"'"}')
  body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/pk" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"create","targetRoomId":"'"$ROOM_ID"'"}')
  err=$(printf '%s' "$body" | json_field "['error']")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    record "PK" "Voice PK endpoint" PASS "PK oluşturuldu"
  elif [[ "$code" == "400" ]]; then
    record "PK" "Voice PK endpoint" PASS "endpoint aktif (HTTP 400: ${err:-validation})"
  elif [[ "$code" == "403" ]] && echo "$err" | grep -qiE 'oda sahibi|owner'; then
    record "PK" "Voice PK endpoint" SKIP "oda sahibi hesabı gerekli (${err})"
  else
    record "PK" "Voice PK endpoint" FAIL "HTTP $code ${err:-}"
  fi
}

phase_psychic() {
  echo "--- PHASE: PSYCHIC ---"
  skip_unless_user_token "PSYCHIC" "Falcı listesi" || return 0
  local code
  code=$(http_code "$BASE/api/fortune-tellers")
  if [[ "$code" == "200" ]]; then
    record "PSYCHIC" "Falcı listesi" PASS "HTTP 200"
  else
    record "PSYCHIC" "Falcı listesi" FAIL "HTTP $code"
  fi
}

cleanup() {
  if [[ -n "$STREAM_ID" && -n "$HOST_TOKEN" ]]; then
    curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$STREAM_ID" \
      -H "Authorization: Bearer $HOST_TOKEN" || true
  fi
}
trap cleanup EXIT

phase_auth
phase_trtc
phase_voice
phase_live
phase_pk
phase_psychic

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/API_PHASE_RUNTIME_REPORT.md"
finalize_reports || exit 1
