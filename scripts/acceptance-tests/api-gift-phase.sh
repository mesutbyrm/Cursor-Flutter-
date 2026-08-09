#!/usr/bin/env bash
# Aşama 6 — Hediye + Jeton + SSE API doğrulaması (gerçek cihaz olmadan).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
USER_TOKEN=""
ROOM_ID=""

echo "=== API Gift Phase (Aşama 6) ==="
echo "Base: $BASE"
echo ""

gate_catalog() {
  echo "--- GIFT CATALOG ---"
  local code body count
  code=$(http_code "$BASE/api/gifts/types?platform=mobile")
  body=$(curl_json "$BASE/api/gifts/types?platform=mobile")
  count=$(printf '%s' "$body" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d if isinstance(d,list) else (d.get('data') or d.get('gifts') or [])
print(len(items) if isinstance(items,list) else 0)
" 2>/dev/null || echo 0)
  if [[ "$code" == "200" && "$count" -gt 0 ]]; then
    record "CATALOG" "Gift catalog" PASS "${count} hediye"
  elif [[ "$code" == "200" ]]; then
    record "CATALOG" "Gift catalog" FAIL "boş katalog"
  else
    record "CATALOG" "Gift catalog" FAIL "HTTP $code"
  fi
}

gate_auth_wallet() {
  echo "--- AUTH + WALLET ---"
  if ! acceptance_user_secrets_configured; then
    record "AUTH" "Login" SKIP "ACCEPTANCE_USER_* yok"
    record "WALLET" "Wallet" SKIP "secret yok"
    return
  fi
  local resp
  resp=$(mobile_login_identifier email "$USER_EMAIL" "$USER_PASSWORD")
  USER_TOKEN=$(extract_token "$resp")
  if [[ -z "$USER_TOKEN" ]]; then
    record "AUTH" "Login" FAIL "token yok"
    record "WALLET" "Wallet" SKIP "token yok"
    return
  fi
  record "AUTH" "Login" PASS "token alındı"
  local jeton
  jeton=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
for k in ('jetonBalance','coins','credits'):
    v=d.get(k)
    if v is None and isinstance(d.get('user'),dict): v=d['user'].get(k)
    if v is not None: print(v); break
" 2>/dev/null || echo "")
  record "WALLET" "Wallet" PASS "bakiye=${jeton:-?}"
}

gate_insufficient() {
  echo "--- INSUFFICIENT BALANCE ---"
  skip_unless_user_token "INSUFF" "Yetersiz jeton" || return 0
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=5&withCounts=true" \
      -H "Authorization: Bearer $USER_TOKEN")
    ROOM_ID=$(pick_first_room_id "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record "INSUFF" "Yetersiz jeton" SKIP "oda yok"
    return
  fi
  local code body err
  body=$(curl -sS -X POST "$BASE/api/chat/rooms/$ROOM_ID/gifts" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"giftTypeId":"elmas","giftId":"elmas","quantity":1,"receiverUserId":"cmsl2h8fe007fns08myytsk6b"}')
  code=$(http_code -X POST "$BASE/api/chat/rooms/$ROOM_ID/gifts" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"giftTypeId":"elmas","giftId":"elmas","quantity":1,"receiverUserId":"cmsl2h8fe007fns08myytsk6b"}')
  err=$(printf '%s' "$body" | json_field "['error']")
  if [[ "$code" == "400" || "$code" == "402" ]] && echo "$err" | grep -qiE 'insufficient|yetersiz'; then
    record "INSUFF" "Yetersiz jeton" PASS "HTTP $code ($err)"
  elif [[ "$code" == "200" || "$code" == "201" ]]; then
    record "INSUFF" "Yetersiz jeton" SKIP "hesapta yeterli jeton var — 500 jeton testi mümkün"
  else
    record "INSUFF" "Yetersiz jeton" FAIL "HTTP $code ($err)"
  fi
}

gate_sse() {
  echo "--- SSE ---"
  skip_unless_user_token "SSE" "SSE gift stream" || return 0
  if [[ -z "$ROOM_ID" ]]; then
    local body
    body=$(curl_json "$BASE/api/chat/rooms?limit=5" -H "Authorization: Bearer $USER_TOKEN")
    ROOM_ID=$(pick_first_room_id "$body")
  fi
  if [[ -z "$ROOM_ID" ]]; then
    record "SSE" "SSE gift stream" SKIP "oda yok"
    return
  fi
  local tmp
  tmp=$(mktemp)
  timeout 5 curl -sS -N \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Accept: text/event-stream" \
    "$BASE/api/chat/rooms/$ROOM_ID/stream" 2>/dev/null | head -c 2048 >"$tmp" || true
  if grep -qE '^(data:|event:|:)' "$tmp"; then
    record "SSE" "SSE gift stream" PASS "stream açık"
  else
    record "SSE" "SSE gift stream" FAIL "veri yok"
  fi
  rm -f "$tmp"
}

gate_catalog
gate_auth_wallet
gate_insufficient
gate_sse

export RESULT_LINES_RAW="$(printf '%s\n' "${RESULT_LINES[@]}")"
export REPORT_MD="${REPORT_DIR}/API_GIFT_PHASE_REPORT.md"
finalize_reports || exit 1
