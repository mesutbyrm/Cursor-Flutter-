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

ROOM_ID="${MUSIC_PROBE_ROOM:-cmoohrbr}"
OUT="${ROOT}/docs/M7_MUSIC_SSE_CAPTURE.md"

echo "=== Music room probe (room=$ROOM_ID) ==="

if ! bootstrap_user_token; then
  echo "SKIP: kullanıcı girişi başarısız"
  exit 0
fi
TOKEN="$USER_TOKEN"

# Arama
search_body=$(curl_json "$BASE/api/youtube/search?q=Tarkan%20Simarik&limit=3" \
  -H "Authorization: Bearer $TOKEN")
video_id=$(printf '%s' "$search_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('items') or d.get('results') or [])
if not items: sys.exit(1)
it=items[0]
print(it.get('videoId') or it.get('id') or '')
" 2>/dev/null || echo "")
title=$(printf '%s' "$search_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('items') or d.get('results') or [])
if not items: sys.exit(1)
print(items[0].get('title') or 'Probe')
" 2>/dev/null || echo "Probe")
[[ -z "$video_id" ]] && video_id="dQw4w9WgXcQ"

# song-request
sr_payload=$(python3 -c "import json; print(json.dumps({'videoId':'$video_id','title':'''$title''','youtubeUrl':'https://www.youtube.com/watch?v=$video_id','priority':True}))")
sr_body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$sr_payload")
sr_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$sr_payload")

# SSE snippet (8s)
sse_tmp=$(mktemp)
timeout 8 curl -sS -N \
  -H "Authorization: Bearer $TOKEN" \
  -H "Accept: text/event-stream" \
  "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 16384 >"$sse_tmp" || true

# youtube-stream
ys_body=$(curl_json "$BASE/api/chat/youtube-stream?videoId=$video_id" \
  -H "Authorization: Bearer $TOKEN")

utc=$(date -u +"%Y-%m-%d %H:%M UTC")
cat >"$OUT" <<EOF
# M7 — Müzik probe yakalama (üretim)

**Tarih:** $utc  
**Oda:** \`$ROOM_ID\`  
**Hesap:** \`$USER_EMAIL\` (acceptance test)  
**Üretim:** \`$BASE\`

> Otomatik üretildi: \`bash scripts/probe-music-room.sh\`

---

## POST song-request → HTTP $sr_code

\`\`\`json
$(printf '%s' "$sr_body" | python3 -m json.tool 2>/dev/null || echo "$sr_body")
\`\`\`

---

## GET youtube-stream?videoId=$video_id

\`\`\`json
$(printf '%s' "$ys_body" | python3 -m json.tool 2>/dev/null || echo "$ys_body")
\`\`\`

---

## SSE stream (ilk 16KB)

\`\`\`
$(sed 's/\`/\\`/g' "$sse_tmp" | head -80)
\`\`\`

---

## Arama (youtube/search)

\`\`\`json
$(printf '%s' "$search_body" | python3 -m json.tool 2>/dev/null | head -40)
\`\`\`
EOF

rm -f "$sse_tmp"
echo "Wrote $OUT (song-request HTTP $sr_code)"
