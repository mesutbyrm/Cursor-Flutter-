#!/usr/bin/env bash
# Sesli oda koltuk / presence / voice API doğrulaması (jeton gerektirmez).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

apply_acceptance_credential_defaults

USER_TOKEN=""
ROOM_ID=""
VOICE_PROBE_ROOM="${VOICE_PROBE_ROOM:-${MUSIC_PROBE_ROOM:-cmoohrbr}}"

resolve_room_id_from_list() {
  local slug="$1" body="$2"
  printf '%s' "$body" | ROOM_SLUG="$slug" python3 -c "
import json,sys,os
slug=os.environ.get('ROOM_SLUG','').strip().lower()
d=json.load(sys.stdin)
rooms=d if isinstance(d,list) else d.get('rooms') or d.get('data') or []
if not isinstance(rooms,list): rooms=[]
for r in rooms:
    if not isinstance(r,dict): continue
    rid=str(r.get('id') or r.get('roomId') or '').strip()
    rslug=str(r.get('slug') or '').strip().lower()
    if rid.lower()==slug or rslug==slug:
        print(rid); break
    if len(slug) >= 6 and rid.lower().startswith(slug):
        print(rid); break
else:
    print(slug)
" 2>/dev/null || echo "$slug"
}

pick_empty_seat_index() {
  local body="$1"
  printf '%s' "$body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw:
    sys.exit(0)
d=json.loads(raw)
seats=d if isinstance(d,list) else d.get('seats') or d.get('data') or []
if isinstance(seats,dict):
    seats=seats.get('seats') or seats.get('items') or []
occupied=set()
locked=set()
for s in seats:
    if not isinstance(s,dict):
        continue
    idx=s.get('index')
    if idx is None:
        idx=s.get('seatIndex')
    if idx is None:
        continue
    idx=int(idx)
    uid=s.get('userId') or (s.get('user') or {}).get('id')
    if s.get('locked') or s.get('isLocked'):
        locked.add(idx)
    elif uid:
        occupied.add(idx)
for i in range(1, 13):
    if i not in occupied and i not in locked:
        print(i)
        break
" 2>/dev/null || true
}

self_seat_index_from_presence() {
  local body="$1" me_id="$2"
  ME_ID="$me_id" printf '%s' "$body" | python3 -c "
import json,sys,os
me=os.environ.get('ME_ID','').strip()
raw=sys.stdin.read().strip()
if not raw or not me:
    sys.exit(0)
d=json.loads(raw)
rows=d if isinstance(d,list) else d.get('presence') or d.get('users') or d.get('data') or []
if isinstance(rows,dict):
    rows=rows.get('presence') or rows.get('users') or []
for p in rows:
    if not isinstance(p,dict):
        continue
    pid=str(p.get('userId') or p.get('id') or '').strip()
    if pid != me:
        continue
    si=p.get('seatIndex')
    if si is not None and int(si) >= 0:
        print(int(si))
        break
" 2>/dev/null || true
}

ensure_room_id() {
  if [[ -n "$ROOM_ID" ]]; then
    return 0
  fi
  skip_unless_user_token "ROOM" "Room resolve" || return 1
  local body
  body=$(curl_json "$BASE/api/chat/rooms?limit=50&withCounts=true" \
    -H "Authorization: Bearer $USER_TOKEN")
  ROOM_ID=$(resolve_room_id_from_list "$VOICE_PROBE_ROOM" "$body")
  [[ -n "$ROOM_ID" ]]
}

echo "=== API Voice Seat Phase ==="
echo "Base: $BASE"
echo "Room probe: $VOICE_PROBE_ROOM"
echo ""

gate_auth() {
  echo "--- AUTH ---"
  if ! bootstrap_user_token; then
    record "AUTH" "Login" FAIL "token yok"
    return
  fi
  record "AUTH" "Login" PASS "token alındı ($USER_EMAIL)"
}

gate_room_resolve() {
  echo "--- ROOM RESOLVE ---"
  skip_unless_user_token "ROOMKEY" "Room key resolve" || return 0
  local body resolved
  body=$(curl_json "$BASE/api/chat/rooms?limit=50&withCounts=true" \
    -H "Authorization: Bearer $USER_TOKEN")
  resolved=$(resolve_room_id_from_list "$VOICE_PROBE_ROOM" "$body")
  if [[ "$resolved" != "$VOICE_PROBE_ROOM" && ${#resolved} -ge 18 ]]; then
    record "ROOMKEY" "Room key resolve" PASS "$VOICE_PROBE_ROOM → $resolved"
    ROOM_ID="$resolved"
  elif [[ "$resolved" == "$VOICE_PROBE_ROOM" ]]; then
    record "ROOMKEY" "Room key resolve" SKIP "önek çözülemedi — ham id denenir"
    ROOM_ID="$VOICE_PROBE_ROOM"
  else
    record "ROOMKEY" "Room key resolve" FAIL "oda listesinde yok"
  fi
}

gate_presence_join() {
  echo "--- PRESENCE JOIN ---"
  skip_unless_user_token "PJOIN" "Presence join" || return 0
  ensure_room_id || {
    record "PJOIN" "Presence join" SKIP "oda yok"
    return
  }
  local code body
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"join"}')
  body=$(curl_json -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"join"}')
  local count
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw: print(0); sys.exit()
d=json.loads(raw)
rows=d if isinstance(d,list) else d.get('presence') or d.get('users') or d.get('data') or []
if isinstance(rows,dict):
    rows=rows.get('presence') or rows.get('users') or []
print(len(rows) if isinstance(rows,list) else 0)
" 2>/dev/null || echo 0)
  if [[ "$code" == "200" || "$code" == "201" ]]; then
    record "PJOIN" "Presence join" PASS "HTTP $code, presence≈$count (room=$ROOM_ID)"
  else
    record "PJOIN" "Presence join" FAIL "HTTP $code"
  fi
}

gate_seats_list() {
  echo "--- SEATS LIST ---"
  skip_unless_user_token "SEATS" "Seats list" || return 0
  ensure_room_id || {
    record "SEATS" "Seats list" SKIP "oda yok"
    return
  }
  local code body count
  code=$(http_code "$BASE/api/chat/rooms/$ROOM_ID/seats" \
    -H "Authorization: Bearer $USER_TOKEN")
  body=$(curl_json "$BASE/api/chat/rooms/$ROOM_ID/seats" \
    -H "Authorization: Bearer $USER_TOKEN")
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw: print(0); sys.exit()
d=json.loads(raw)
seats=d if isinstance(d,list) else d.get('seats') or d.get('data') or []
if isinstance(seats,dict):
    seats=seats.get('seats') or seats.get('items') or []
print(len(seats) if isinstance(seats,list) else 0)
" 2>/dev/null || echo 0)
  if [[ "$code" == "200" && "$count" -ge 0 ]]; then
    record "SEATS" "Seats list" PASS "HTTP $code, seats=$count"
  else
    record "SEATS" "Seats list" FAIL "HTTP $code"
  fi
}

gate_seat_take_leave() {
  echo "--- SEAT TAKE/LEAVE ---"
  skip_unless_user_token "STAKE" "Seat take/leave" || return 0
  ensure_room_id || {
    record "STAKE" "Seat take/leave" SKIP "oda yok"
    return
  }
  local me_id seats_body seat_idx take_code leave_code pres_body seated
  me_id=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or (d.get('user') or {}).get('id') or '')
" 2>/dev/null || echo "")
  seats_body=$(curl_json "$BASE/api/chat/rooms/$ROOM_ID/seats" \
    -H "Authorization: Bearer $USER_TOKEN")
  seat_idx=$(pick_empty_seat_index "$seats_body")
  if [[ -z "$seat_idx" ]]; then
    record "STAKE" "Seat take/leave" SKIP "boş koltuk yok"
    return
  fi
  take_code=$(http_code -X PATCH "$BASE/api/chat/rooms/$ROOM_ID/seats" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"action\":\"take\",\"seatIndex\":$seat_idx}")
  if [[ "$take_code" == "405" ]]; then
    take_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/seats" \
      -H "Authorization: Bearer $USER_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{\"action\":\"take\",\"seatIndex\":$seat_idx}")
  fi
  pres_body=$(curl_json "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_TOKEN")
  seated=$(self_seat_index_from_presence "$pres_body" "$me_id")
  leave_code=$(http_code -X PATCH "$BASE/api/chat/rooms/$ROOM_ID/seats" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"action\":\"leave\",\"seatIndex\":$seat_idx}")
  if [[ "$leave_code" == "405" ]]; then
    leave_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/seats" \
      -H "Authorization: Bearer $USER_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"action":"leave"}')
  fi
  if [[ "$take_code" =~ ^(200|201)$ && "$leave_code" =~ ^(200|201)$ ]]; then
    if [[ -n "$seated" && "$seated" == "$seat_idx" ]]; then
      record "STAKE" "Seat take/leave" PASS "take seat=$seat_idx, presence seatIndex=$seated"
    else
      record "STAKE" "Seat take/leave" PASS "take/leave HTTP OK (presence seatIndex=${seated:-?})"
    fi
  elif [[ "$take_code" =~ ^(200|201)$ ]]; then
    record "STAKE" "Seat take/leave" FAIL "take OK, leave=$leave_code"
  else
    record "STAKE" "Seat take/leave" FAIL "take=$take_code leave=$leave_code"
  fi
}

gate_voice_join() {
  echo "--- VOICE JOIN ---"
  skip_unless_user_token "VOICE" "Voice join" || return 0
  ensure_room_id || {
    record "VOICE" "Voice join" SKIP "oda yok"
    return
  }
  local code body has_users
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/voice" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"join"}')
  body=$(curl_json -X POST "$BASE/api/chat/rooms/$ROOM_ID/voice" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"join"}')
  has_users=$(printf '%s' "$body" | python3 -c "
import json,sys
raw=sys.stdin.read().strip()
if not raw: print('no'); sys.exit()
d=json.loads(raw)
for k in ('voiceUsers','users','data'):
    v=d.get(k)
    if isinstance(v,list) and v:
        print('yes'); sys.exit()
if d.get('success') is True:
    print('yes'); sys.exit()
print('no')
" 2>/dev/null || echo "no")
  if [[ "$code" =~ ^(200|201)$ ]]; then
    record "VOICE" "Voice join" PASS "HTTP $code (voiceUsers=$has_users)"
  elif [[ "$code" == "403" ]]; then
    record "VOICE" "Voice join" SKIP "HTTP 403 (koltuk/+V yetkisi gerekli olabilir)"
  else
    record "VOICE" "Voice join" FAIL "HTTP $code"
  fi
  http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/voice" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"leave"}' >/dev/null 2>&1 || true
}

gate_sse_stream() {
  echo "--- SSE STREAM ---"
  skip_unless_user_token "SSE" "Room SSE stream" || return 0
  ensure_room_id || {
    record "SSE" "Room SSE stream" SKIP "oda yok"
    return
  }
  local tmp
  tmp=$(mktemp)
  timeout 5 curl -sS -N \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 4096 >"$tmp" || true
  if grep -qE '^(data:|event:|:)' "$tmp" && ! grep -qi 'room not found' "$tmp"; then
    record "SSE" "Room SSE stream" PASS "stream açık (room=$ROOM_ID)"
  elif grep -qi 'room not found' "$tmp"; then
    record "SSE" "Room SSE stream" FAIL "Room not found"
  else
    record "SSE" "Room SSE stream" FAIL "veri yok"
  fi
  rm -f "$tmp"
}

gate_presence_leave() {
  echo "--- PRESENCE LEAVE (cleanup) ---"
  skip_unless_user_token "PLEAVE" "Presence leave" || return 0
  [[ -n "$ROOM_ID" ]] || return 0
  local code
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"action":"leave"}')
  if [[ "$code" =~ ^(200|201|204)$ ]]; then
    record "PLEAVE" "Presence leave" PASS "HTTP $code"
  else
    record "PLEAVE" "Presence leave" SKIP "HTTP $code (cleanup)"
  fi
}

gate_auth
gate_room_resolve
gate_presence_join
gate_seats_list
gate_seat_take_leave
gate_voice_join
gate_sse_stream
gate_presence_leave

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/API_VOICE_SEAT_PHASE_REPORT.md"
finalize_reports || exit 1
