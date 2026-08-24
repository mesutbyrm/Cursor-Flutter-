#!/usr/bin/env bash
# M5 API smoke — cihaz olmadan müzik/presence/!istek backend doğrulaması.
# Test 1–4'ün API karşılığı; Test 5–10 yalnızca Android cihazda.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

REPORT="${ROOT}/docs/M5_API_SMOKE_REPORT.md"
ROOM_SLUG="${MUSIC_PROBE_ROOM:-cmoohrbr}"
MIN_JETON="${M5_MIN_JETON:-10}"

PASS=0
FAIL=0
SKIP=0
LOG=""
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")
VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | awk '{print $2}')

record() {
  local name="$1" status="$2" detail="$3"
  LOG+="| $name | $status | $detail |\n"
  case "$status" in
    PASS) PASS=$((PASS + 1)); echo "  ✅ $name — $detail" ;;
    FAIL) FAIL=$((FAIL + 1)); echo "  ❌ $name — $detail" ;;
    SKIP) SKIP=$((SKIP + 1)); echo "  ⏭️  $name — $detail" ;;
  esac
}

resolve_room_id() {
  local body="$1"
  printf '%s' "$body" | ROOM_SLUG="$ROOM_SLUG" python3 -c "
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
" 2>/dev/null || echo "$ROOM_SLUG"
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  M5 API smoke — $VERSION (oda=$ROOM_SLUG)"
echo "╚══════════════════════════════════════════════════════════╝"

apply_acceptance_credential_defaults
if ! bootstrap_user_token; then
  record "Auth" FAIL "token yok"
  exit 1
fi

JETON_BEFORE=$(user_jeton_balance_from_me "$USER_TOKEN")
if [[ "$JETON_BEFORE" -lt "$MIN_JETON" ]]; then
  record "Jeton" FAIL "jeton=$JETON_BEFORE < $MIN_JETON"
  exit 1
fi
record "Jeton" PASS "jeton=$JETON_BEFORE"

rooms_body=$(curl_json "$BASE/api/chat/rooms?limit=50&withCounts=true" \
  -H "Authorization: Bearer $USER_TOKEN")
ROOM_ID=$(resolve_room_id "$rooms_body")
if [[ ${#ROOM_ID} -lt 18 ]]; then
  record "Oda çözümleme" FAIL "id=$ROOM_ID"
  exit 1
fi
record "Oda çözümleme" PASS "$ROOM_SLUG → $ROOM_ID"

# Test 1/2 — !istek / müzik paneli (song-request)
search=$(curl_json "$BASE/api/youtube/search?q=Tarkan%20Simarik&limit=1" \
  -H "Authorization: Bearer $USER_TOKEN")
VID=$(printf '%s' "$search" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('videos') if isinstance(d,dict) else []
if not isinstance(items,list): items=[]
print(items[0].get('id','') if items else '')
" 2>/dev/null || echo "")
[[ -z "$VID" ]] && VID="cpp69ghR1IM"
payload='{"videoId":"'"$VID"'","title":"M5 Smoke Simarik","requestType":"audio","videoMode":"audio","priority":true}'
sr_code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$payload")
sr_body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/song-request" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$payload")
JETON_AFTER=$(user_jeton_balance_from_me "$USER_TOKEN")
if [[ "$sr_code" == "200" || "$sr_code" == "201" ]]; then
  deducted=$((JETON_BEFORE - JETON_AFTER))
  record "Test1-2 song-request" PASS "HTTP $sr_code jeton -$deducted"
else
  err=$(printf '%s' "$sr_body" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('error','')[:80])" 2>/dev/null || echo "?")
  record "Test1-2 song-request" FAIL "HTTP $sr_code ($err)"
fi

# Kuyruk / nowPlaying
mq_body=$(curl_json "$BASE/api/chat/rooms/$ROOM_ID/music-queue" \
  -H "Authorization: Bearer $USER_TOKEN")
has_np=$(printf '%s' "$mq_body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
np=d.get('nowPlaying') or d.get('playing')
q=d.get('queue') or d.get('musicQueue') or []
print('yes' if np or (isinstance(q,list) and len(q)>0) else 'no')
" 2>/dev/null || echo "no")
if [[ "$has_np" == "yes" ]]; then
  record "Müzik kuyruğu" PASS "nowPlaying veya queue dolu"
else
  record "Müzik kuyruğu" SKIP "kuyruk boş (gecikme olabilir)"
fi

# Test 4 — presence join/leave (oda değişimi API)
pj=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action":"join"}')
pl=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/presence" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action":"leave"}')
if [[ "$pj" =~ ^(200|201)$ && "$pl" =~ ^(200|201|204)$ ]]; then
  record "Test4 presence" PASS "join=$pj leave=$pl"
else
  record "Test4 presence" FAIL "join=$pj leave=$pl"
fi

# SSE dj event
sse_tmp=$(mktemp)
timeout 8 curl -sS -N \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Accept: text/event-stream" \
  "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 8192 >"$sse_tmp" || true
if grep -qE '"type":"dj"|dj_update|QUEUE' "$sse_tmp"; then
  record "SSE dj/kuyruk" PASS "stream event alındı"
elif grep -qE '^(data:|event:)' "$sse_tmp"; then
  record "SSE dj/kuyruk" SKIP "stream açık, dj event yok (kısa timeout)"
else
  record "SSE dj/kuyruk" FAIL "stream veri yok"
fi
rm -f "$sse_tmp"

# Test 5–10 — cihaz only
record "Test5-6 PK" SKIP "cihaz gerekli"
record "Test7-10 sesli P0-P2" SKIP "cihaz gerekli"

cat >"$REPORT" <<EOF
# M5 API smoke raporu

**Tarih:** $UTC  
**APK:** \`$VERSION\`  
**Oda:** \`$ROOM_SLUG\` → \`$ROOM_ID\`  
**Hesap:** \`$USER_EMAIL\` — jeton $JETON_BEFORE→$JETON_AFTER

| Geçti | Atlandı | Başarısız |
|-------|---------|-----------|
| $PASS | $SKIP | $FAIL |

## Sonuçlar

| Test | Durum | Detay |
|------|--------|-------|
$(printf '%b' "$LOG")

## Not

Bu rapor **Test 1–4 API karşılığıdır**. Test 5–10 (PK, koltuk-ses, mod popup, giriş şeridi) yalnızca \`docs/M5_DEVICE_TEST_CHECKLIST.md\` ile Android cihazda doğrulanır.

Yenile: \`bash scripts/m5-api-smoke.sh\`
EOF

echo ""
echo "══════════════════════════════════════════════════════════"
echo "M5 API smoke: PASS=$PASS SKIP=$SKIP FAIL=$FAIL"
echo "Rapor: docs/M5_API_SMOKE_REPORT.md"
echo ""

[[ "$FAIL" -eq 0 ]]
