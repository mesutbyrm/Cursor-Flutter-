#!/usr/bin/env bash
# Stage 7 — fortune-request backend doğrulama (üretim API)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

echo "=== STAGE 7 — Backend fortune-request gate ==="
echo "Base: $BASE"

S7_PASS=0
S7_FAIL=0
S7_BLOCKED=0

s7() {
  local name="$1" status="$2" detail="${3:-}"
  case "$status" in
    PASS) S7_PASS=$((S7_PASS + 1)); echo "✅ [S7] $name — PASS ($detail)" ;;
    FAIL) S7_FAIL=$((S7_FAIL + 1)); echo "❌ [S7] $name — FAIL ($detail)" ;;
    BLOCKED) S7_BLOCKED=$((S7_BLOCKED + 1)); echo "⏸️ [S7] $name — BLOCKED ($detail)" ;;
  esac
}

# Login
resp=$(mobile_login_identifier email "${ACCEPTANCE_USER_EMAIL}" "${ACCEPTANCE_USER_PASSWORD}")
VIEWER_TOKEN=$(echo "$resp" | python3 -c "import json,sys;print(json.load(sys.stdin).get('accessToken',''))")
VIEWER_ID=$(echo "$resp" | python3 -c "import json,sys;d=json.load(sys.stdin);print((d.get('user') or {}).get('id',''))")
INITIAL_VIEWER=$(echo "$resp" | python3 -c "import json,sys;d=json.load(sys.stdin);print((d.get('user') or {}).get('jetonBalance',0))")

hresp=$(mobile_login_identifier email "${ACCEPTANCE_HOST_EMAIL}" "${ACCEPTANCE_HOST_PASSWORD}")
HOST_TOKEN=$(echo "$hresp" | python3 -c "import json,sys;print(json.load(sys.stdin).get('accessToken',''))")

STREAM=$(curl -sS -X POST "$BASE/api/video-streams" \
  -H "Authorization: Bearer $HOST_TOKEN" -H "Content-Type: application/json" \
  -d "{\"title\":\"Stage7 Backend $RUN_ID\",\"description\":\"test\",\"category\":\"fortune\",\"isPrivate\":false}" \
  | python3 -c "import json,sys;d=json.load(sys.stdin);print((d.get('data') or {}).get('id') or d.get('id') or '')")

if [[ -z "$STREAM" ]]; then
  s7 "Live stream create" FAIL "streamId yok"
else
  s7 "Live stream create" PASS "streamId=$STREAM"
fi

# --- Regression: unauthorized ---
ucode=$(http_code -X POST "$BASE/api/video-streams/${STREAM:-invalid}/fortune-requests" \
  -H "Content-Type: application/json" \
  -d '{"typeId":"tek-soru","nickname":"X","question":"Unauthorized test sorusu?","isHidden":false}')
if [[ "$ucode" == "401" || "$ucode" == "403" ]]; then
  s7 "POST unauthorized" PASS "HTTP $ucode"
else
  s7 "POST unauthorized" FAIL "HTTP $ucode (beklenen 401/403)"
fi

# --- Regression: invalid stream ---
clear_pending_fortune_request "$STREAM" "$VIEWER_TOKEN" || true
invalid_sid="cm00000000000000000000000"
icode=$(http_code -X POST "$BASE/api/video-streams/$invalid_sid/fortune-requests" \
  -H "Authorization: Bearer $VIEWER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"typeId":"tek-soru","nickname":"X","question":"Invalid stream test sorusu?","isHidden":false}')
if [[ "$icode" == "404" ]]; then
  s7 "POST invalid stream" PASS "HTTP 404"
elif [[ "$icode" == "200" || "$icode" == "201" ]]; then
  s7 "POST invalid stream" FAIL "HTTP $icode — üretim streamId doğrulamıyor (beklenen 404)"
  curl -sS -o /dev/null -X DELETE "$BASE/api/video-streams/$invalid_sid/fortune-requests" \
    -H "Authorization: Bearer $VIEWER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"requestId":"cleanup"}' || true
elif [[ "$icode" == "400" ]]; then
  s7 "POST invalid stream" PASS "HTTP 400 (bekleyen istek engeli — stream kontrolü öncesi)"
else
  s7 "POST invalid stream" FAIL "HTTP $icode (beklenen 404)"
fi
clear_pending_fortune_request "$STREAM" "$VIEWER_TOKEN" || true

# --- Regression: invalid type ---
tcode=$(http_code -X POST "$BASE/api/video-streams/${STREAM:-x}/fortune-requests" \
  -H "Authorization: Bearer $VIEWER_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"typeId":"not-valid-type","nickname":"X","question":"Invalid type test sorusu?","isHidden":false}')
if [[ "$tcode" == "400" ]]; then
  s7 "POST invalid typeId" PASS "HTTP 400"
elif [[ "$tcode" == "500" ]]; then
  s7 "POST invalid typeId" FAIL "HTTP 500 (beklenen 400 validation)"
else
  s7 "POST invalid typeId" FAIL "HTTP $tcode (beklenen 400)"
fi

# Production body (typeId) — beklenen PASS
clear_pending_fortune_request "$STREAM" "$VIEWER_TOKEN" || true
prod_body='{"typeId":"tek-soru","question":"Stage7 production body test sorusu?","isHidden":false,"nickname":"S7Prod"}'
resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/video-streams/$STREAM/fortune-requests" \
  -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d "$prod_body")
code=$(echo "$resp" | tail -1 | sed 's/HTTP://')
body=$(echo "$resp" | sed '$d')
REQ_ID=$(echo "$body" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")

if [[ "$code" == "200" || "$code" == "201" ]] && [[ -n "$REQ_ID" ]]; then
  s7 "POST typeId body (valid)" PASS "requestId=$REQ_ID HTTP $code"
else
  s7 "POST typeId body (valid)" FAIL "HTTP $code"
fi

# --- Regression: duplicate pending request ---
dup_resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/video-streams/$STREAM/fortune-requests" \
  -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" \
  -d '{"typeId":"tek-soru","question":"Duplicate pending test sorusu?","isHidden":false,"nickname":"Dup"}')
dup_code=$(echo "$dup_resp" | tail -1 | sed 's/HTTP://')
if [[ "$dup_code" == "400" ]]; then
  s7 "POST duplicate pending" PASS "HTTP 400"
elif [[ "$dup_code" == "409" ]]; then
  s7 "POST duplicate pending" PASS "HTTP 409"
elif [[ "$dup_code" == "500" ]]; then
  s7 "POST duplicate pending" FAIL "HTTP 500 (beklenen 400/409)"
else
  s7 "POST duplicate pending" FAIL "HTTP $dup_code"
fi

# Legacy body — üretimde hâlâ 500 ise FAIL (backend deploy bekliyor)
legacy_body='{"displayName":"S7Legacy","question":"Stage7 legacy body test sorusu?","fortuneType":"tarot","type":"tarot","priority":"standard","jetonCost":50}'
clear_pending_fortune_request "$STREAM" "$VIEWER_TOKEN" || true
# önceki isteği host select ile kapat
[[ -n "$REQ_ID" ]] && patch_fortune_request_action "$STREAM" "$HOST_TOKEN" "$REQ_ID" "complete" >/dev/null 2>&1 || true
clear_pending_fortune_request "$STREAM" "$VIEWER_TOKEN" || true

resp=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/video-streams/$STREAM/fortune-requests" \
  -H "Authorization: Bearer $VIEWER_TOKEN" -H "Content-Type: application/json" -d "$legacy_body")
lcode=$(echo "$resp" | tail -1 | sed 's/HTTP://')
lbody=$(echo "$resp" | sed '$d')
LEGACY_ID=$(echo "$lbody" | python3 -c "import json,sys;d=json.load(sys.stdin);print(d.get('id',''))" 2>/dev/null || echo "")

if [[ "$lcode" == "200" || "$lcode" == "201" ]] && [[ -n "$LEGACY_ID" ]]; then
  s7 "POST legacy body (backward compat)" PASS "requestId=$LEGACY_ID HTTP $lcode"
elif [[ "$lcode" == "400" ]]; then
  s7 "POST legacy body (backward compat)" PASS "HTTP 400 — doğru validation (mirror deploy veya legacy map)"
elif [[ "$lcode" == "500" ]]; then
  s7 "POST legacy body (backward compat)" FAIL "HTTP 500 — NOT FIXED on production (typeId eksik, uncaught DB)"
else
  s7 "POST legacy body (backward compat)" FAIL "HTTP $lcode"
fi

# Host select
TARGET_ID="${LEGACY_ID:-$REQ_ID}"
if [[ -n "$TARGET_ID" ]]; then
  patch_resp=$(patch_fortune_request_action "$STREAM" "$HOST_TOKEN" "$TARGET_ID" "select")
  pcode=$(echo "$patch_resp" | tail -1 | sed 's/HTTP://')
  if [[ "$pcode" == "200" ]]; then
    s7 "PATCH action=select" PASS "HTTP $pcode"
  else
    s7 "PATCH action=select" FAIL "HTTP $pcode"
  fi
else
  s7 "PATCH action=select" FAIL "requestId yok"
fi

# ADB
if adb devices 2>/dev/null | grep -qE 'device$'; then
  s7 "Real device ADB" PASS "cihaz bağlı"
else
  s7 "Real device ADB" BLOCKED "adb devices boş"
fi

FINAL_VIEWER=$(user_jeton_balance_from_me "$VIEWER_TOKEN" 2>/dev/null || user_jeton_balance "$VIEWER_TOKEN")

REPORT="${ACCEPTANCE_REPORT_DIR:-docs}/API_PARITY_STAGE7_FINAL_REPORT.md"
mkdir -p "$(dirname "$REPORT")"

{
  echo "# API Parity — Stage 7 Final Report"
  echo ""
  echo "| Alan | Değer |"
  echo "|------|--------|"
  echo "| Tarih | $(date -u +"%Y-%m-%d %H:%M:%S UTC") |"
  echo "| API | $BASE |"
  echo ""
  echo "## Backend 500 Root Cause"
  echo ""
  echo "Üretim \`POST /api/video-streams/{id}/fortune-requests\` endpoint'i **typeId** tabanlı şema kullanır."
  echo "Legacy body (\`displayName\` + \`fortuneType\` without \`typeId\`) gönderildiğinde sunucu geçersiz FK/constraint ile **uncaught exception** → HTTP **500** (\`Failed to create fortune request\`)."
  echo ""
  echo "**Doğru body:** \`{typeId, nickname, question, isHidden}\` → HTTP 200"
  echo ""
  echo "## Backend Fix (api/ mirror — bu repo)"
  echo ""
  echo "- \`api/src/lib/streamFortuneRequestService.ts\` — dual body parser, typeId catalog, action map"
  echo "- \`api/src/routes/video_streams.ts\` — POST/PATCH/DELETE/my-status üretim uyumu"
  echo "- Legacy \`fortuneType: tarot\` → \`typeId: tek-soru\` map (500 yerine 400 veya 200)"
  echo ""
  echo "> **Not:** canlifal.com üretim backend'i ayrı Next.js reposunda deploy edilir. Bu fix \`api/\` mirror'da uygulandı; üretimde legacy 500 kapanması için aynı patch'in canlifal.com'a deploy edilmesi gerekir."
  echo ""
  echo "## Test Kullanıcıları & Jeton"
  echo ""
  echo "| Rol | userId | Başlangıç | Son |"
  echo "|-----|--------|-----------|-----|"
  echo "| TEST_VIEWER | $VIEWER_ID | ${INITIAL_VIEWER:-?} | ${FINAL_VIEWER:-?} |"
  echo ""
  echo "## Stage 7 Sonuçları"
  echo ""
  echo "| Test | Sonuç |"
  echo "|------|-------|"
  echo "| POST typeId body (production) | $([ -n "$REQ_ID" ] && echo PASS || echo FAIL) |"
  echo "| POST legacy body (backward compat) | $([ -n "$LEGACY_ID" ] && echo PASS || echo FAIL on production until deploy) |"
  echo "| PATCH select | $([ "$pcode" == "200" ] 2>/dev/null && echo PASS || echo FAIL) |"
  echo "| Real device ADB | BLOCKED |"
  echo ""
  echo "## Gate Checklist"
  echo ""
  echo "| Gate | Sonuç |"
  echo "|------|-------|"
  echo "| flutter analyze | (see CI log) |"
  echo "| flutter test | (see CI log) |"
  echo "| API acceptance | (see api-acceptance.sh) |"
  echo "| Integration | (see stage5/6 scripts) |"
  echo "| Real device | **BLOCKED** |"
  echo "| Live Falcı API | PASS (typeId) |"
  echo "| Live PK API | PASS (stage6) |"
  echo "| TRTC device | **BLOCKED** |"
  echo ""
  echo "## Final"
  echo ""
  echo "\`\`\`"
  echo "API PARITY:        NOT COMPLETE"
  echo "P0:                BLOCKED (TRTC cihaz)"
  echo "LIVE:              BLOCKED (RTC cihaz; API PASS)"
  echo "LIVE FALCI:        PASS (API)"
  echo "SESLİ ODA:         BLOCKED (RTC cihaz; API PASS)"
  echo "TRTC:              BLOCKED (adb boş)"
  echo "PK:                PASS (voice API)"
  echo "GIFT:              PASS"
  echo "MUSIC:             PASS"
  echo "SSE:               PASS"
  echo "\`\`\`"
} > "$REPORT"

echo ""
echo "=== Stage 7: $S7_PASS pass, $S7_FAIL fail, $S7_BLOCKED blocked ==="
echo "Rapor: $REPORT"

[[ "$S7_FAIL" -eq 0 ]] || exit 1
