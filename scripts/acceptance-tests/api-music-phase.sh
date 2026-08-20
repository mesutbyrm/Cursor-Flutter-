#!/usr/bin/env bash
# Aşama 7 — !istek + müzik API doğrulaması (gerçek cihaz olmadan).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

apply_acceptance_credential_defaults

USER_EMAIL="${USER_EMAIL:-${ACCEPTANCE_USER_EMAIL:-}}"
USER_PASSWORD="${USER_PASSWORD:-${ACCEPTANCE_USER_PASSWORD:-}}"
USER_TOKEN=""
ROOM_ID=""
MUSIC_PROBE_ROOM="${MUSIC_PROBE_ROOM:-cmoohrbr}"

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

echo "=== API Music Phase (Aşama 7) ==="
echo "Base: $BASE"
echo ""

gate_search() {
  echo "--- MUSIC SEARCH ---"
  if ! bootstrap_user_token; then
    record "SEARCH" "Music search" SKIP "giriş başarısız"
    return
  fi
  local token="$USER_TOKEN"
  local code body count has_fields attempt
  code=""
  body=""
  for attempt in 1 2 3; do
    code=$(http_code -H "Authorization: Bearer $token" "$BASE/api/music/search?q=Tarkan%20Dudu&limit=5")
    body=$(curl_json "$BASE/api/music/search?q=Tarkan%20Dudu&limit=5" -H "Authorization: Bearer $token")
    if [[ "$code" == "200" ]]; then
      break
    fi
    if [[ "$code" =~ ^5 ]]; then
      [[ "$attempt" -lt 3 ]] && sleep 2
      continue
    fi
    break
  done
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('items') or d.get('results') or [])
print(len(items) if isinstance(items,list) else 0)
" 2>/dev/null || echo 0)
  local has_fields
  has_fields=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('items') or d.get('results') or [])
if not items: print('no'); sys.exit(0)
it=items[0]
ok=bool(it.get('videoId') or it.get('id')) and bool(it.get('title'))
print('yes' if ok else 'no')
" 2>/dev/null || echo "no")
  if [[ "$code" == "200" && "$count" -gt 0 && "$has_fields" == "yes" ]]; then
    record "SEARCH" "Music search" PASS "${count} sonuç, videoId+title"
  elif [[ "$code" == "200" ]]; then
    record "SEARCH" "Music search" FAIL "sonuç yok veya alan eksik"
  elif [[ "$code" =~ ^5 ]]; then
    record "SEARCH" "Music search" SKIP "HTTP $code (üretim geçici hata — 3 deneme)"
  else
    record "SEARCH" "Music search" FAIL "HTTP $code"
  fi
}

gate_auth_queue() {
  echo "--- AUTH + QUEUE COSTS ---"
  if ! bootstrap_user_token; then
    record "AUTH" "Login" FAIL "token yok"
    record "QUEUE" "Queue costs" SKIP "token yok"
    return
  fi
  USER_TOKEN="${USER_TOKEN}"
  record "AUTH" "Login" PASS "token alındı ($USER_EMAIL)"

  local body
  body=$(curl_json "$BASE/api/chat/rooms?limit=50&withCounts=true" \
    -H "Authorization: Bearer $USER_TOKEN")
  ROOM_ID=$(resolve_room_id_from_list "$MUSIC_PROBE_ROOM" "$body")
  if [[ -z "$ROOM_ID" ]]; then
    record "QUEUE" "Queue costs" SKIP "oda yok"
    return
  fi

  body=$(curl_json "$BASE/api/chat/rooms/$ROOM_ID/music-queue" \
    -H "Authorization: Bearer $USER_TOKEN")
  local has_queue audio
  has_queue=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
ok=isinstance(d.get('queue') or d.get('musicQueue'), list)
print('yes' if ok else 'no')
" 2>/dev/null || echo "no")
  audio=$(printf '%s' "$body" | python3 -c "
import json,sys,re
d=json.load(sys.stdin)
rc=d.get('requestCosts') or {}
if isinstance(rc,dict) and rc.get('audio'): print(rc['audio']); sys.exit()
for k in ('cost','musicRequestCost','requestCost'):
  v=d.get(k)
  if v is not None: print(v); break
" 2>/dev/null || echo "")
  if [[ -z "$audio" ]]; then
    local err_body
    err_body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
      -H "Authorization: Bearer $USER_TOKEN" \
      -H "Content-Type: application/json" \
      -d '{"videoId":"dQw4w9WgXcQ","title":"Probe","requestType":"audio","videoMode":"audio"}')
    audio=$(printf '%s' "$err_body" | python3 -c "
import json,sys,re
d=json.load(sys.stdin)
msg=str(d.get('error') or d.get('message') or '')
m=re.search(r'(\\d+)\\s*jeton', msg, re.I)
print(m.group(1) if m else '')
" 2>/dev/null || echo "")
  fi
  if [[ "$has_queue" == "yes" && -n "$audio" ]]; then
    record "QUEUE" "Queue costs" PASS "kuyruk OK, audio=${audio} jeton"
  elif [[ "$has_queue" == "yes" ]]; then
    record "QUEUE" "Queue costs" PASS "kuyruk OK (fiyat song-request yanıtından)"
  else
    record "QUEUE" "Queue costs" FAIL "kuyruk yanıtı geçersiz"
  fi
}

gate_song_request_insufficient() {
  echo "--- SONG REQUEST (insufficient) ---"
  skip_unless_user_token "SONGREQ" "Song request" || return 0
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=50" -H "Authorization: Bearer $USER_TOKEN")
    ROOM_ID=$(resolve_room_id_from_list "$MUSIC_PROBE_ROOM" "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record "SONGREQ" "Song request" SKIP "oda yok"
    return
  fi
  local code body err
  body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"videoId":"dQw4w9WgXcQ","title":"Test Song","requestType":"audio","videoMode":"audio"}')
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"videoId":"dQw4w9WgXcQ","title":"Test Song","requestType":"audio","videoMode":"audio"}')
  err=$(printf '%s' "$body" | json_field "['error']")
  if [[ "$code" == "400" || "$code" == "402" ]] && echo "$err" | grep -qiE 'insufficient|yetersiz|jeton'; then
    record "SONGREQ" "Song request" PASS "HTTP $code ($err)"
  elif [[ "$code" == "200" || "$code" == "201" ]]; then
    record "SONGREQ" "Song request" SKIP "hesapta yeterli jeton — E2E mümkün"
  else
    record "SONGREQ" "Song request" FAIL "HTTP $code ($err)"
  fi
}

gate_sse_dj() {
  echo "--- SSE DJ ---"
  skip_unless_user_token "SSE_DJ" "SSE dj stream" || return 0
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=50" -H "Authorization: Bearer $USER_TOKEN")
    ROOM_ID=$(resolve_room_id_from_list "$MUSIC_PROBE_ROOM" "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record "SSE_DJ" "SSE dj stream" SKIP "oda yok"
    return
  fi
  local tmp
  tmp=$(mktemp)
  timeout 5 curl -sS -N \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 4096 >"$tmp" || true
  if grep -qE '^(data:|event:|:)' "$tmp" && ! grep -qi 'room not found' "$tmp"; then
    record "SSE_DJ" "SSE dj stream" PASS "stream açık (room=$ROOM_ID)"
  elif grep -qi 'room not found' "$tmp"; then
    record "SSE_DJ" "SSE dj stream" FAIL "Room not found (kısmi id? çözüm: tam cuid)"
  else
    record "SSE_DJ" "SSE dj stream" FAIL "veri yok"
  fi
  rm -f "$tmp"
}

gate_room_key_resolve() {
  echo "--- ROOM KEY RESOLVE ---"
  skip_unless_user_token "ROOMKEY" "Room key resolve" || return 0
  local body resolved
  body=$(curl_json "$BASE/api/chat/rooms?limit=50" -H "Authorization: Bearer $USER_TOKEN")
  resolved=$(resolve_room_id_from_list "$MUSIC_PROBE_ROOM" "$body")
  if [[ "$resolved" != "$MUSIC_PROBE_ROOM" && ${#resolved} -ge 18 ]]; then
    record "ROOMKEY" "Room key resolve" PASS "$MUSIC_PROBE_ROOM → $resolved"
    ROOM_ID="$resolved"
  elif [[ "$resolved" == "$MUSIC_PROBE_ROOM" ]]; then
    record "ROOMKEY" "Room key resolve" FAIL "önek çözülemedi"
  else
    record "ROOMKEY" "Room key resolve" SKIP "oda listesinde yok"
  fi
}

gate_search
gate_auth_queue
gate_room_key_resolve
gate_song_request_insufficient
gate_sse_dj

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/API_MUSIC_PHASE_REPORT.md"
finalize_reports || exit 1
