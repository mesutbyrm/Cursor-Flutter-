#!/usr/bin/env bash
# Canlı falcı oda API smoke — yerel mirror veya CANLIFAL_BASE_URL.
set -euo pipefail

BASE="${CANLIFAL_BASE_URL:-http://127.0.0.1:3000}"
BASE="${BASE%/}"
PASS=0
FAIL=0

check_code() {
  local name="$1" expected="$2" actual="$3"
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
    PASS=$((PASS + 1))
  else
    echo "FAIL $name → HTTP $actual (beklenen: $expected)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Fortune room endpoint smoke: $BASE ==="

# Oturumsuz — 401/404 değil 401 tercih (mirror'da requireAuth)
code=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/api/room/fs-smoke-test" || echo "000")
check_code "GET /api/room/{id} (oturumsuz)" "401|403" "$code"

code=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/api/room/signal?sessionId=x" || echo "000")
check_code "GET /api/room/signal (oturumsuz)" "401|403" "$code"

code=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/api/user/active-sessions" || echo "000")
check_code "GET /api/user/active-sessions (oturumsuz)" "401|403" "$code"

code=$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$BASE/api/trtc/token" \
  -H "Content-Type: application/json" \
  -d '{"roomId":"smoke","userId":"u1"}' || echo "000")
check_code "POST /api/trtc/token" "200|401" "$code"

code=$(curl -sS -o /dev/null -w "%{http_code}" "$BASE/api/fortune-tellers/toggle-online" || echo "000")
check_code "GET /api/fortune-tellers/toggle-online (oturumsuz)" "401|403" "$code"

echo ""
echo "Özet: $PASS OK, $FAIL FAIL"
[[ "$FAIL" -eq 0 ]]
