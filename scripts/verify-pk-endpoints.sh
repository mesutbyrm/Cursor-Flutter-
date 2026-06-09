#!/usr/bin/env bash
# PK Battle endpoint smoke test
set -euo pipefail

BASE="${CANLIFAL_BASE_URL:-https://canlifal.com}"
ROOM_ID="${PK_TEST_ROOM_ID:-test-room}"

pass=0
fail=0

check() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  local ok=0
  if [[ "$actual" == "$expected" ]]; then
    ok=1
  elif [[ "$expected" == *"|"* ]]; then
    local part
    IFS='|' read -ra _codes <<< "$expected"
    for part in "${_codes[@]}"; do
      if [[ "$actual" == "$part" ]]; then ok=1; break; fi
    done
  fi
  if [[ "$ok" -eq 1 ]]; then
    echo "OK   $name → HTTP $actual"
    pass=$((pass + 1))
  else
    echo "FAIL $name → HTTP $actual (beklenen: $expected)"
    fail=$((fail + 1))
  fi
}

echo "=== PK smoke test: $BASE ==="

code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/pk/history")
check "GET /api/pk/history" "200|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/pk/battles/test-id")
check "GET /api/pk/battles/:id" "200|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/pk/battles" \
  -H "Content-Type: application/json" -d '{}')
check "POST /api/pk/battles (oturumsuz)" "401|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" \
  "$BASE/api/chat/rooms/$ROOM_ID/pk-battle")
check "GET /api/chat/rooms/:id/pk-battle" "200|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" -X POST \
  "$BASE/api/chat/rooms/$ROOM_ID/pk-battle" \
  -H "Content-Type: application/json" \
  -d '{"action":"create","opponentRoomId":"other"}')
check "POST /api/chat/rooms/:id/pk-battle" "401|404|400" "$code"

echo "=== Sonuç: $pass OK, $fail FAIL ==="
[[ "$fail" -eq 0 ]]
