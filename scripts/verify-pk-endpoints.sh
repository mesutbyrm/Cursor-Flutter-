#!/usr/bin/env bash
# PK Battle endpoint smoke test — birleşik Faz 1–3 + geriye dönük yollar.
set -euo pipefail

MAIN_BASE="${CANLIFAL_BASE_URL:-https://canlifal.com}"
PK_BASE="${PK_API_BASE_URL:-https://canlifalapi.abacusai.app}"
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

echo "=== PK smoke test (birleşik): $PK_BASE ==="

code=$(curl -s -o /dev/null -w "%{http_code}" "$PK_BASE/api/pk/active")
check "GET /api/pk/active" "200" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" \
  "$PK_BASE/api/pk/leaderboard?period=weekly&metric=score")
check "GET /api/pk/leaderboard" "200" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PK_BASE/api/pk/request" \
  -H "Content-Type: application/json" -d '{}')
check "POST /api/pk/request (oturumsuz)" "401" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PK_BASE/api/pk/room" \
  -H "Content-Type: application/json" -d '{}')
check "POST /api/pk/room (oturumsuz)" "401" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" "$PK_BASE/api/pk/me/history")
check "GET /api/pk/me/history (oturumsuz)" "401" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" "$PK_BASE/api/pk/me/invites")
check "GET /api/pk/me/invites (oturumsuz)" "401" "$code"

echo "=== PK smoke test (geriye dönük): $MAIN_BASE ==="

code=$(curl -s -o /dev/null -w "%{http_code}" "$MAIN_BASE/api/pk/history")
check "GET /api/pk/history (main)" "200|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" \
  "$MAIN_BASE/api/chat/rooms/$ROOM_ID/pk")
check "GET /api/chat/rooms/:id/pk" "200|404" "$code"

echo "=== Sonuç: $pass OK, $fail FAIL ==="
[[ "$fail" -eq 0 ]]
