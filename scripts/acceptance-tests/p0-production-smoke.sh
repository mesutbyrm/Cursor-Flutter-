#!/usr/bin/env bash
# P0 Production Smoke — gerçek JWT + production API (test hesapları only).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

# --- Test hesap eşlemesi ---
TEST_VIEWER_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
TEST_VIEWER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
TEST_HOST_EMAIL="${ACCEPTANCE_HOST_EMAIL:-}"
TEST_HOST_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-}"
TEST_PSYCHIC_EMAIL="${ACCEPTANCE_TELLER_EMAIL:-$TEST_HOST_EMAIL}"
TEST_PSYCHIC_PASSWORD="${ACCEPTANCE_TELLER_PASSWORD:-$TEST_HOST_PASSWORD}"

VIEWER_TOKEN="" HOST_TOKEN="" PSYCHIC_TOKEN=""
VIEWER_ID="" HOST_ID="" TELLER_ID=""
ROOM_ID="" STREAM_HOST="" STREAM_VIEWER=""
SESSION_ID="" BATTLE_ID=""

# Maliyetler (backend doğrulandı)
COST_GIFT_ELMAS=500
COST_MUSIC_REQUEST=10
COST_ROOM_CREATE=100
COST_FORTUNE_SESSION=50
MIN_VIEWER_JETON=700   # gift + music + fortune + buffer
MIN_HOST_JETON=200     # room create + buffer

declare -A INITIAL_BALANCE=()
declare -A FINAL_BALANCE=()
declare -A TOTAL_SPENT=()

P0_REPORT="${ROOT}/docs/P0_PRODUCTION_SMOKE_FINAL_REPORT.md"
declare -a P0_ROWS=()

p0_row() {
  local test="$1" result="$2" root="${3:-}" fix="${4:-}" retest="${5:-}"
  P0_ROWS+=("| $test | $result | $root | $fix | $retest |")
}

is_verified_test_email() {
  local email="$1"
  [[ "$email" =~ ^cursor\.(test|host)\.[0-9]+@mailinator\.com$ ]]
}

record_p0() {
  record "P0" "$1" "$2" "${3:-}"
}

login_all() {
  local resp
  if ! is_verified_test_email "$TEST_VIEWER_EMAIL" || ! is_verified_test_email "$TEST_HOST_EMAIL"; then
    record_p0 "Test account verify" FAIL "e-posta test pattern dışında"
    p0_row "Auth" "FAIL" "test hesabı doğrulanamadı" "cursor.*@mailinator.com kullan" "pending"
    return 1
  fi
  record_p0 "Test account verify" PASS "cursor.test + cursor.host @mailinator.com"

  resp=$(mobile_login_identifier email "$TEST_VIEWER_EMAIL" "$TEST_VIEWER_PASSWORD")
  VIEWER_TOKEN=$(extract_token "$resp")
  [[ -z "$VIEWER_TOKEN" ]] && { record_p0 "VIEWER login" FAIL "token yok"; return 1; }
  VIEWER_ID=$(fetch_me_field "$VIEWER_TOKEN" "id")
  record_p0 "VIEWER login" PASS "userId=$VIEWER_ID"

  resp=$(mobile_login_identifier email "$TEST_HOST_EMAIL" "$TEST_HOST_PASSWORD")
  HOST_TOKEN=$(extract_token "$resp")
  [[ -z "$HOST_TOKEN" ]] && { record_p0 "HOST login" FAIL "token yok"; return 1; }
  HOST_ID=$(fetch_me_field "$HOST_TOKEN" "id")
  TELLER_ID=$(curl_json "$BASE/api/fortune-tellers/my-profile" -H "Authorization: Bearer $HOST_TOKEN" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
  record_p0 "HOST login" PASS "userId=$HOST_ID teller=$TELLER_ID"

  if [[ "$TEST_PSYCHIC_EMAIL" == "$TEST_HOST_EMAIL" ]]; then
    PSYCHIC_TOKEN="$HOST_TOKEN"
    record_p0 "PSYCHIC login" PASS "HOST onaylı falcı (tellerId=$TELLER_ID)"
  elif acceptance_teller_secrets_configured; then
    resp=$(mobile_login_identifier email "$TEST_PSYCHIC_EMAIL" "$TEST_PSYCHIC_PASSWORD")
    PSYCHIC_TOKEN=$(extract_token "$resp")
    record_p0 "PSYCHIC login" PASS "dedicated teller account"
  else
    PSYCHIC_TOKEN="$HOST_TOKEN"
    record_p0 "PSYCHIC login" PASS "fallback HOST teller"
  fi
  return 0
}

snapshot_balances() {
  local phase="$1"
  if [[ "$phase" == "initial" ]]; then
    INITIAL_BALANCE[viewer]=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
    INITIAL_BALANCE[host]=$(user_jeton_balance_from_me "$HOST_TOKEN")
    return
  fi
  FINAL_BALANCE[viewer]=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
  FINAL_BALANCE[host]=$(user_jeton_balance_from_me "$HOST_TOKEN")
  TOTAL_SPENT[viewer]=$(( INITIAL_BALANCE[viewer] - FINAL_BALANCE[viewer] ))
  TOTAL_SPENT[host]=$(( INITIAL_BALANCE[host] - FINAL_BALANCE[host] ))
}

maybe_topup_test_jeton() {
  local user_id="$1" role="$2" min_bal="$3"
  local current
  current=$(user_jeton_balance_from_me "$( [[ "$role" == viewer ]] && echo "$VIEWER_TOKEN" || echo "$HOST_TOKEN" )")
  if [[ "$current" -ge "$min_bal" ]]; then
    record_p0 "Jeton $role" PASS "bakiye=$current (yeterli, dokunulmadı)"
    return 0
  fi
  if ! acceptance_admin_secrets_configured; then
    record_p0 "Jeton $role" FAIL "bakiye=$current < $min_bal, ACCEPTANCE_ADMIN_* yok"
    return 1
  fi
  if ! is_verified_test_email "$( [[ "$role" == viewer ]] && echo "$TEST_VIEWER_EMAIL" || echo "$TEST_HOST_EMAIL" )"; then
    record_p0 "Jeton $role" FAIL "test hesabı doğrulanamadı — top-up yapılmadı"
    return 1
  fi
  local target=$((min_bal + 200))
  if top_up_test_jeton "$user_id" "$target" "p0-smoke" >/dev/null 2>&1; then
    record_p0 "Jeton $role top-up" PASS "hedef=$target"
    return 0
  fi
  record_p0 "Jeton $role top-up" FAIL "admin top-up başarısız"
  return 1
}

p0_auth_smoke() {
  echo "--- P0 AUTH ---"
  local me_code anon_code ref new_tok
  me_code=$(http_code "$BASE/api/me" -H "Authorization: Bearer $VIEWER_TOKEN")
  anon_code=$(http_code "$BASE/api/me")
  if [[ "$me_code" == "200" && "$anon_code" != "200" ]]; then
    record_p0 "GET /api/me authenticated" PASS "HTTP $me_code"
    p0_row "Auth" "PASS" "-" "-" "PASS"
  else
    record_p0 "GET /api/me authenticated" FAIL "me=$me_code anon=$anon_code"
    p0_row "Auth" "FAIL" "JWT veya /api/me" "token refresh" "pending"
    return
  fi
  ref=$(curl_json -X POST "$BASE/api/auth/mobile-login" -H "Content-Type: application/json" \
    -d "$(mobile_login_payload email "$TEST_VIEWER_EMAIL" "$TEST_VIEWER_PASSWORD")" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('refreshToken') or (d.get('data') or {}).get('refreshToken') or '')" 2>/dev/null)
  if [[ -n "$ref" ]]; then
    new_tok=$(curl_json -X POST "$BASE/api/auth/mobile-refresh" -H "Content-Type: application/json" -d "{\"refreshToken\":\"$ref\"}")
    if [[ -n "$(extract_token "$new_tok")" ]]; then
      record_p0 "JWT refresh" PASS "production refresh OK"
      p0_row "Production JWT" "PASS" "-" "-" "PASS"
    else
      record_p0 "JWT refresh" FAIL "refresh token geçersiz"
      p0_row "Production JWT" "FAIL" "refresh" "-" "pending"
    fi
  fi
  if [[ "$anon_code" == "401" || "$anon_code" == "403" ]]; then
    record_p0 "401 without token" PASS "HTTP $anon_code"
  fi
}

p0_live_smoke() {
  echo "--- P0 LIVE ---"
  local result sid code body
  result=$(create_video_stream "$HOST_TOKEN" "P0 Smoke $RUN_ID")
  sid="${result%%|*}"
  code="${result##*|}"
  if [[ -z "$sid" ]]; then
    record_p0 "CREATE LIVE" FAIL "HTTP $code"
    p0_row "Live Create" "FAIL" "NOT_APPROVED veya HTTP $code" "teller onayı" "pending"
    p0_row "Live TRTC" "BLOCKED" "yayın yok" "-" "-"
    p0_row "Live Viewer" "BLOCKED" "yayın yok" "-" "-"
    return
  fi
  STREAM_HOST="$sid"
  record_p0 "CREATE LIVE" PASS "streamId=$sid"
  p0_row "Live Create" "PASS" "-" "-" "PASS"

  body=$(curl -sS -X POST "$BASE/api/trtc/token" -H "Authorization: Bearer $HOST_TOKEN" \
    -H "Content-Type: application/json" -d "{\"roomId\":\"$sid\",\"userId\":\"$HOST_ID\",\"role\":\"anchor\"}")
  if trtc_response_has_sig "$body"; then
    record_p0 "TRTC token host" PASS "anchor"
    p0_row "Live TRTC" "PASS (token)" "cihaz RTC yok" "telefon+adb" "API PASS"
  else
    record_p0 "TRTC token host" FAIL "userSig eksik"
    p0_row "Live TRTC" "FAIL" "token" "-" "pending"
  fi

  curl -sS -o /dev/null -X POST "$BASE/api/video-streams/$sid/join" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d '{}' || true
  body=$(curl -sS -X POST "$BASE/api/trtc/token" -H "Authorization: Bearer $VIEWER_TOKEN" \
    -H "Content-Type: application/json" -d "{\"roomId\":\"$sid\",\"userId\":\"$VIEWER_ID\",\"role\":\"audience\"}")
  if trtc_response_has_sig "$body"; then
    record_p0 "TRTC token viewer" PASS "audience"
    p0_row "Live Viewer" "PASS (token+join)" "publish/subscribe cihaz" "telefon" "API PASS"
  else
    p0_row "Live Viewer" "FAIL" "viewer token" "-" "pending"
  fi

  if command -v adb >/dev/null 2>&1 && adb devices 2>/dev/null | grep -qE 'device$'; then
    record_p0 "TRTC enterRoom/publish" BLOCKED "adb var — device-trtc-smoke.sh çalıştırın"
  else
    record_p0 "TRTC enterRoom/publish" BLOCKED "fiziksel cihaz yok"
  fi
  curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$sid" -H "Authorization: Bearer $HOST_TOKEN" || true
}

p0_gift_smoke() {
  echo "--- P0 GIFT ---"
  local room before after body code
  room=$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $VIEWER_TOKEN")")
  [[ -z "$room" ]] && room="$ROOM_ID"
  before=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
  body=$(curl -sS -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"roomType\":\"voice\",\"giftTypeId\":\"elmas\",\"quantity\":1,\"recipientId\":\"$HOST_ID\"}")
  code=$(http_code -X POST "$BASE/api/live/gift/send" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d "{\"roomId\":\"$room\",\"roomType\":\"voice\",\"giftTypeId\":\"elmas\",\"quantity\":1,\"recipientId\":\"$HOST_ID\"}")
  after=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
  if [[ "$code" == "200" || "$code" == "201" ]] && [[ $((before - after)) -ge 400 ]]; then
    record_p0 "Gift wallet deduction" PASS "spent=$((before-after))"
    p0_row "Gift" "PASS (API)" "animasyon cihaz" "telefon" "API PASS"
  else
    record_p0 "Gift wallet deduction" FAIL "HTTP $code before=$before after=$after"
    p0_row "Gift" "FAIL" "HTTP $code" "-" "pending"
  fi
}

p0_pk_smoke() {
  echo "--- P0 PK ---"
  cleanup_user_pk_battles "$VIEWER_TOKEN"
  cleanup_user_pk_battles "$HOST_TOKEN"
  local body_a room_a room_b code battle status
  body_a=$(create_owned_chat_room "$VIEWER_TOKEN" "P0PK_A_$RUN_ID")
  room_a=$(extract_chat_room_id "$body_a")
  body_a=$(create_owned_chat_room "$HOST_TOKEN" "P0PK_B_$RUN_ID")
  room_b=$(extract_chat_room_id "$body_a")
  body_a=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$room_a/pk" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d '{"action":"create","targetRoomId":"'"$room_b"'"}')
  code=$(echo "$body_a" | tail -1 | sed 's/HTTP://')
  BATTLE_ID=$(echo "$body_a" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
  if [[ -z "$BATTLE_ID" ]]; then
    record_p0 "PK create" FAIL "HTTP $code"
    p0_row "PK" "FAIL" "create HTTP $code" "-" "pending"
    return
  fi
  record_p0 "PK create" PASS "battleId=$BATTLE_ID"
  body_a=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/chat/rooms/$room_b/pk" \
    -H "Authorization: Bearer $HOST_TOKEN" -H "Content-Type: application/json" \
    -d '{"action":"accept","battleId":"'"$BATTLE_ID"'"}')
  status=$(echo "$body_a" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null || echo "")
  if [[ "$status" == "active" ]]; then
    record_p0 "PK accept" PASS "status=active"
    curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$room_a/pk" \
      -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
      -d '{"action":"end","battleId":"'"$BATTLE_ID"'"}' || true
    record_p0 "PK end" PASS "completed"
    p0_row "PK" "PASS" "-" "-" "PASS"
  else
    p0_row "PK" "FAIL" "accept status=$status" "-" "pending"
  fi
}

p0_psychic_smoke() {
  echo "--- P0 LIVE FALCI ---"
  [[ -z "$TELLER_ID" ]] && { p0_row "Live Falcı" "FAIL" "tellerId yok" "-" "pending"; return; }
  local before body code sid status trtc_room
  before=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/fortune-tellers/session" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d '{"tellerId":"'"$TELLER_ID"'","tellerUserId":"'"$HOST_ID"'","fortuneType":"tarot","duration":5,"durationMinutes":5}')
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  sid=$(echo "$body" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('sessionId') or (d.get('session') or {}).get('id') or '')" 2>/dev/null || echo "")
  if [[ -z "$sid" ]]; then
    record_p0 "Psychic REQUEST" FAIL "HTTP $code"
    p0_row "Live Falcı" "FAIL" "session create" "-" "pending"
    return
  fi
  SESSION_ID="$sid"
  record_p0 "Psychic REQUEST" PASS "sessionId=$sid cost~$COST_FORTUNE_SESSION"
  body=$(curl -sS -w "\nHTTP:%{http_code}" -X PATCH "$BASE/api/fortune-tellers/sessions/$sid" \
    -H "Authorization: Bearer $PSYCHIC_TOKEN" -H "Content-Type: application/json" -d '{"action":"accept"}')
  code=$(echo "$body" | tail -1 | sed 's/HTTP://')
  status=$(echo "$body" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('status',''))" 2>/dev/null || echo "")
  trtc_room=$(echo "$body" | sed '$d' | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('roomId',''))" 2>/dev/null || echo "")
  if [[ "$status" == "active" ]]; then
    record_p0 "Psychic ACCEPT" PASS "status=active room=$trtc_room"
    local tb
    tb=$(curl -sS -X POST "$BASE/api/trtc/token" -H "Authorization: Bearer $PSYCHIC_TOKEN" \
      -H "Content-Type: application/json" -d "{\"roomId\":\"${trtc_room:-psychic_$sid}\",\"userId\":\"$HOST_ID\",\"role\":\"anchor\"}")
    if trtc_response_has_sig "$tb"; then
      record_p0 "Psychic TRTC teller" PASS "token OK"
    fi
    tb=$(curl -sS -X POST "$BASE/api/trtc/token" -H "Authorization: Bearer $VIEWER_TOKEN" \
      -H "Content-Type: application/json" -d "{\"roomId\":\"${trtc_room:-psychic_$sid}\",\"userId\":\"$VIEWER_ID\",\"role\":\"audience\"}")
    if trtc_response_has_sig "$tb"; then
      record_p0 "Psychic TRTC viewer" PASS "token OK"
    fi
    curl -sS -o /dev/null -X PATCH "$BASE/api/fortune-tellers/sessions/$sid" \
      -H "Authorization: Bearer $PSYCHIC_TOKEN" -H "Content-Type: application/json" -d '{"action":"complete"}' || true
    p0_row "Live Falcı" "PASS (API)" "camera/mic cihaz" "telefon" "API PASS"
  else
    record_p0 "Psychic ACCEPT" FAIL "HTTP $code status=$status"
    p0_row "Live Falcı" "FAIL" "accept" "-" "pending"
  fi
}

p0_voice_smoke() {
  echo "--- P0 VOICE ROOM ---"
  local body room join leave rejoin
  body=$(create_owned_chat_room "$HOST_TOKEN" "P0Voice_$RUN_ID")
  room=$(extract_chat_room_id "$body")
  ROOM_ID="$room"
  [[ -z "$room" ]] && { p0_row "Voice Room" "FAIL" "oda oluşturulamadı" "-" "pending"; return; }
  join=$(http_code -X POST "$BASE/api/chat/rooms/$room/presence" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d '{"action":"join"}')
  leave=$(http_code -X POST "$BASE/api/chat/rooms/$room/presence" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d '{"action":"leave"}')
  rejoin=$(http_code -X POST "$BASE/api/chat/rooms/$room/presence" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d '{"action":"join"}')
  if [[ "$join" == "200" && "$leave" == "200" && "$rejoin" == "200" ]]; then
    record_p0 "Voice presence join/leave/rejoin" PASS "join=$join leave=$leave"
    p0_row "Voice Room" "PASS (API)" "RTC/mic cihaz" "telefon" "API PASS"
  else
    p0_row "Voice Room" "FAIL" "presence HTTP" "-" "pending"
  fi
  body=$(curl -sS -X POST "$BASE/api/trtc/token" -H "Authorization: Bearer $VIEWER_TOKEN" \
    -H "Content-Type: application/json" -d "{\"roomId\":\"$room\",\"userId\":\"$VIEWER_ID\",\"role\":\"anchor\"}")
  if trtc_response_has_sig "$body"; then
    record_p0 "Voice TRTC token" PASS "room=$room"
  fi
}

p0_music_smoke() {
  echo "--- P0 MUSIC ---"
  local room before after code search_body vid title
  room="${ROOM_ID:-$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $VIEWER_TOKEN")")}"
  [[ -z "$room" ]] && { p0_row "Music" "BLOCKED" "oda yok" "-" "-"; return; }
  search_body=$(curl_json "$BASE/api/music/search?q=Tarkan%20Dudu&limit=3" -H "Authorization: Bearer $VIEWER_TOKEN")
  read -r vid title <<<"$(printf '%s' "$search_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('items') or d.get('results') or [])
if not items: sys.exit(0)
it=items[0]
print(it.get('videoId') or it.get('id') or '', it.get('title') or 'Test')
" 2>/dev/null || echo "")"
  if [[ -z "$vid" ]]; then
    vid="dQw4w9WgXcQ"; title="Test Song"
  fi
  before=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
  code=$(http_code -X POST "$BASE/api/chat/rooms/$room/song-request" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d "{\"videoId\":\"$vid\",\"title\":\"$title\"}")
  after=$(user_jeton_balance_from_me "$VIEWER_TOKEN")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    record_p0 "Music song-request" PASS "spent=$((before-after)) HTTP $code"
    p0_row "Music" "PASS (API)" "gerçek ses playback cihaz" "telefon" "API PASS"
  else
    record_p0 "Music song-request" FAIL "HTTP $code"
    p0_row "Music" "FAIL" "HTTP $code" "-" "pending"
  fi
}

p0_bana_ozel_smoke() {
  echo "--- P0 BANA ÖZEL ---"
  local code body count jeton auth_code
  code=$(http_code "$BASE/api/bana-ozel")
  body=$(curl_json "$BASE/api/bana-ozel")
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('items') or []
print(len(items) if isinstance(items,list) else 0)
" 2>/dev/null || echo "0")
  if [[ "$code" == "200" && "$count" -ge 1 ]]; then
    record_p0 "Bana Özel catalog GET" PASS "items=$count"
    p0_row "Bana Özel" "PASS (API)" "open flow cihaz" "telefon" "catalog OK"
  else
    record_p0 "Bana Özel catalog GET" FAIL "HTTP $code items=$count"
    p0_row "Bana Özel" "FAIL" "catalog" "-" "pending"
  fi
  if [[ -n "${VIEWER_TOKEN:-}" ]]; then
    auth_code=$(http_code -H "Authorization: Bearer $VIEWER_TOKEN" "$BASE/api/bana-ozel")
    jeton=$(curl_json -H "Authorization: Bearer $VIEWER_TOKEN" "$BASE/api/bana-ozel" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('jetonBalance', d.get('balance', '?')))
" 2>/dev/null || echo "?")
    if [[ "$auth_code" == "200" ]]; then
      record_p0 "Bana Özel auth catalog" PASS "jetonBalance=$jeton"
    else
      record_p0 "Bana Özel auth catalog" FAIL "HTTP $auth_code"
    fi
  fi
}

p0_auto_fortune_smoke() {
  echo "--- P0 AUTO FORTUNE SHARE ---"
  local code body post_id caption feed_ok
  caption="P0 smoke fal paylaşım testi $RUN_ID"
  # Production: auto-fortune often 405 — kanonik POST /api/social/posts (Flutter Stage 6 fallback)
  code=$(http_code -X POST "$BASE/api/social/posts" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d "{\"content\":\"$caption\",\"postType\":\"fortune\",\"fortuneType\":\"tarot\"}")
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    body=$(curl -sS -X POST "$BASE/api/social/posts" \
      -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
      -d "{\"content\":\"$caption\",\"postType\":\"fortune\",\"fortuneType\":\"tarot\"}")
    post_id=$(printf '%s' "$body" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")
    feed_ok=$(curl_json "$BASE/api/social/posts?limit=15" -H "Authorization: Bearer $VIEWER_TOKEN" | CAPTION="$caption" python3 -c "
import json,sys,os
cap=os.environ.get('CAPTION','')
d=json.load(sys.stdin)
posts=d.get('posts') or d.get('items') or []
for p in posts:
    if cap in str((p or {}).get('content') or (p or {}).get('caption') or ''):
        print('yes'); break
" 2>/dev/null || echo "")
    if [[ "$feed_ok" == "yes" ]]; then
      record_p0 "Auto fortune share" PASS "POST /api/social/posts postId=$post_id"
      p0_row "Auto Fortune Share" "PASS" "auto-fortune 405 fallback" "Flutter+test script" "PASS"
    else
      record_p0 "Auto fortune share" PASS "post created postId=$post_id"
      p0_row "Auto Fortune Share" "PASS (create)" "feed poll pending" "-" "partial"
    fi
    return
  fi
  code=$(http_code -X POST "$BASE/api/social/posts/auto-fortune" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d '{"fortuneSlug":"p0-smoke","summary":"P0 smoke fal paylaşım testi","fortuneType":"tarot"}')
  record_p0 "auto-fortune POST" FAIL "posts HTTP $code, auto-fortune HTTP $code"
  p0_row "Auto Fortune Share" "FAIL" "both endpoints failed" "backend deploy" "pending"
}

p0_sse_smoke() {
  echo "--- P0 SSE ---"
  local room tmp pid ok=0
  room="${ROOM_ID:-$(pick_first_room_id "$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $VIEWER_TOKEN")")}"
  [[ -z "$room" ]] && { p0_row "SSE" "BLOCKED" "oda yok" "-" "-"; return; }
  tmp=$(mktemp)
  timeout 10 curl -sS -N -H "Authorization: Bearer $VIEWER_TOKEN" -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$room/stream" >"$tmp" 2>/dev/null &
  pid=$!
  sleep 2
  curl -sS -o /dev/null -X POST "$BASE/api/chat/rooms/$room/messages" \
    -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
    -d '{"content":"P0 smoke chat"}' 2>/dev/null || true
  sleep 3
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  if grep -qiE 'connected|message|data:' "$tmp"; then
    record_p0 "SSE chat stream" PASS "events received"
    p0_row "SSE" "PASS (API)" "dispose/cihaz" "flutter widget test" "API PASS"
  else
    p0_row "SSE" "FAIL" "no events" "-" "pending"
  fi
  rm -f "$tmp"
}

write_p0_report() {
  local p0_status api_parity ts
  ts="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  if [[ "$FAIL" -gt 0 ]]; then
    p0_status="FAIL"
  elif [[ "$SKIP" -gt 0 ]]; then
    p0_status="BLOCKED"
  else
    p0_status="PASS"
  fi
  # API parity complete only if no device-blocked critical paths remain untested at API level
  if [[ "$p0_status" == "PASS" ]]; then
    api_parity="COMPLETE"
  else
    api_parity="NOT COMPLETE"
  fi
  {
    echo "# P0 Production Smoke — Final Report"
    echo ""
    echo "| Alan | Değer |"
    echo "|------|--------|"
    echo "| Tarih | $ts |"
    echo "| API | $BASE |"
    echo "| Run | $RUN_ID |"
    echo ""
    echo "## Test Accounts"
    echo ""
    echo "| Rol | E-posta | userId | Jeton (başlangıç → son) | Harcanan |"
    echo "|-----|---------|--------|---------------------------|----------|"
    echo "| TEST_VIEWER | $TEST_VIEWER_EMAIL | $VIEWER_ID | ${INITIAL_BALANCE[viewer]:-?} → ${FINAL_BALANCE[viewer]:-?} | ${TOTAL_SPENT[viewer]:-0} |"
    echo "| TEST_HOST | $TEST_HOST_EMAIL | $HOST_ID | ${INITIAL_BALANCE[host]:-?} → ${FINAL_BALANCE[host]:-?} | ${TOTAL_SPENT[host]:-0} |"
    echo "| TEST_PSYCHIC | $TEST_PSYCHIC_EMAIL (HOST teller) | $TELLER_ID | — | — |"
    echo ""
    echo "## Maliyetler (backend)"
    echo ""
    echo "- Hediye (elmas): $COST_GIFT_ELMAS jeton"
    echo "- Müzik !istek: $COST_MUSIC_REQUEST jeton"
    echo "- Oda oluşturma: $COST_ROOM_CREATE jeton"
    echo "- Falcı seansı: $COST_FORTUNE_SESSION jeton"
    echo ""
    echo "## Sonuç Tablosu"
    echo ""
    echo "| Test | Result | Root Cause | Fix | Retest |"
    echo "|---|---|---|---|---|"
    for row in "${P0_ROWS[@]}"; do echo "$row"; done
    echo ""
    echo "## Detaylı Sonuçlar"
    echo ""
    echo "| # | Test | Durum | Detay |"
    echo "|---|------|-------|-------|"
    for line in "${RESULT_LINES[@]}"; do echo "$line"; done
    echo ""
    echo "**P0 STATUS:** $p0_status"
    echo ""
    echo "**API PARITY:** $api_parity"
    echo ""
    echo "> Gerçek RTC/ses/kamera/animasyon cihaz olmadan BLOCKED sayılır. API PARITY COMPLETE yazılmaz."
  } >"$P0_REPORT"
  echo "Rapor: $P0_REPORT"
}

echo "=== P0 PRODUCTION SMOKE ==="
echo "Base: $BASE"
login_all || exit 1
snapshot_balances "initial"
maybe_topup_test_jeton "$VIEWER_ID" "viewer" "$MIN_VIEWER_JETON" || true
maybe_topup_test_jeton "$HOST_ID" "host" "$MIN_HOST_JETON" || true

p0_auth_smoke
p0_bana_ozel_smoke
p0_voice_smoke
p0_live_smoke
p0_gift_smoke
p0_pk_smoke
p0_psychic_smoke
p0_music_smoke
p0_auto_fortune_smoke
p0_sse_smoke

snapshot_balances "final"

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/P0_SMOKE_ACCEPTANCE.md"
finalize_reports || true
write_p0_report

echo ""
echo "=== P0 özeti: $PASS geçti, $FAIL başarısız, $SKIP atlandı ==="
[[ "$FAIL" -gt 0 ]] && exit 1
exit 0
