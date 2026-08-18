#!/usr/bin/env bash
# M7 — Üretim müzik probe: song-request + SSE örnek yakalama (JWT gerekli).
# Kullanım: MUSIC_PROBE_ROOM=cmoohrbr bash scripts/probe-music-room.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$SCRIPT_DIR/acceptance-tests/lib.sh"

require_cmd curl python3

apply_acceptance_credential_defaults

ROOM_SLUG="${MUSIC_PROBE_ROOM:-cmoohrbr}"
OUT="${ROOT}/docs/M7_MUSIC_SSE_CAPTURE.md"

echo "=== Music room probe (slug=$ROOM_SLUG) ==="

if ! bootstrap_user_token; then
  echo "SKIP: kullanıcı girişi başarısız"
  exit 0
fi
TOKEN="$USER_TOKEN"

USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")

JETON_BEFORE=$(user_jeton_balance_from_me "$TOKEN")
JETON_NOTE="jeton=$JETON_BEFORE"
if ensure_test_jeton_minimum "$TOKEN" "$USER_ID" "$USER_EMAIL" 50 probe-music 2>/dev/null; then
  JETON_AFTER=$(user_jeton_balance_from_me "$TOKEN")
  JETON_NOTE="jeton ${JETON_BEFORE}→${JETON_AFTER} (admin top-up)"
fi

rooms_body=$(curl_json "$BASE/api/chat/rooms?limit=50" -H "Authorization: Bearer $TOKEN")
ROOM_ID=$(printf '%s' "$rooms_body" | ROOM_SLUG="$ROOM_SLUG" python3 -c "
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
        print(rid)
        break
    if len(slug) >= 6 and rid.lower().startswith(slug):
        print(rid)
        break
else:
    print(slug)
" 2>/dev/null || echo "$ROOM_SLUG")

echo "Resolved room: slug=$ROOM_SLUG id=$ROOM_ID"

search_body=$(curl_json "$BASE/api/youtube/search?q=Tarkan%20Simarik&limit=3" \
  -H "Authorization: Bearer $TOKEN")
video_id=$(printf '%s' "$search_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('videos') if isinstance(d,dict) else d
if not isinstance(items,list):
    items=d.get('items') or d.get('results') or [] if isinstance(d,dict) else (d if isinstance(d,list) else [])
if not items: sys.exit(1)
it=items[0]
print(it.get('videoId') or it.get('id') or '')
" 2>/dev/null || echo "")
title=$(printf '%s' "$search_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('videos') if isinstance(d,dict) else d
if not isinstance(items,list):
    items=d.get('items') or d.get('results') or [] if isinstance(d,dict) else (d if isinstance(d,list) else [])
if not items: sys.exit(1)
print(items[0].get('title') or 'Probe')
" 2>/dev/null || echo "Probe")
[[ -z "$video_id" ]] && video_id="cpp69ghR1IM"

sr_payload=$(python3 -c "import json; print(json.dumps({'videoId':'$video_id','title':'''$title''','youtubeUrl':'https://www.youtube.com/watch?v=$video_id','priority':True}))")
sr_body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_SLUG/song-request" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$sr_payload")
sr_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_SLUG/song-request" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$sr_payload")

sse_tmp=$(mktemp)
timeout 10 curl -sS -N \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: text/event-stream" \
  "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 24576 >"$sse_tmp" || true

ys_body=$(curl_json "$BASE/api/chat/youtube-stream?videoId=$video_id" \
  -H "Authorization: Bearer $TOKEN")

utc=$(date -u +"%Y-%m-%d %H:%M UTC")
cat >"$OUT" <<EOF
# M7 — Müzik probe yakalama (üretim)

**Tarih:** $utc  
**Oda slug:** \`$ROOM_SLUG\`  
**Oda id (SSE):** \`$ROOM_ID\`  
**Hesap:** \`$USER_EMAIL\` — $JETON_NOTE  
**Üretim:** \`$BASE\`

> Otomatik: \`MUSIC_PROBE_ROOM=$ROOM_SLUG bash scripts/probe-music-room.sh\`  
> **Not:** SSE yalnızca tam cuid ile çalışır; slug ile \`Room not found\`. Flutter \`1.0.264+\` düzeltmesi.

---

## POST song-request (slug \`$ROOM_SLUG\`) → HTTP $sr_code

\`\`\`json
$(printf '%s' "$sr_body" | python3 -m json.tool 2>/dev/null || echo "$sr_body")
\`\`\`

---

## GET youtube-stream?videoId=$video_id

\`\`\`json
$(printf '%s' "$ys_body" | python3 -m json.tool 2>/dev/null || echo "$ys_body")
\`\`\`

---

## SSE stream \`$ROOM_ID\` (ilk 24KB)

\`\`\`
$(sed 's/\`/\\`/g' "$sse_tmp" | head -120)
\`\`\`

---

## Arama (youtube/search)

\`\`\`json
$(printf '%s' "$search_body" | python3 -m json.tool 2>/dev/null | head -50)
\`\`\`
EOF

rm -f "$sse_tmp"
echo "Wrote $OUT (song-request HTTP $sr_code, SSE room=$ROOM_ID)"
