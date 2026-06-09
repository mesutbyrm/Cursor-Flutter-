#!/usr/bin/env bash
# P0 endpoint smoke test — canlifal.com veya CANLIFAL_BASE_URL
set -euo pipefail

BASE="${CANLIFAL_BASE_URL:-https://canlifal.com}"
AUTH_FLAG="${1:-}"

pass=0
fail=0

check() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [[ "$actual" == "$expected" ]] || [[ "$expected" == *"|"* && "$actual" =~ ^($expected)$ ]]; then
    echo "OK   $name → HTTP $actual"
    pass=$((pass + 1))
  else
    echo "FAIL $name → HTTP $actual (beklenen: $expected)"
    fail=$((fail + 1))
  fi
}

echo "=== P0 smoke test: $BASE ==="

# Müzik — oturumsuz 401
code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/music/search?q=test")
check "GET /api/music/search (oturumsuz)" "401" "$code"

# TRTC — POST 200
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/trtc/usersig" \
  -H "Content-Type: application/json" \
  -d '{"userId":"smoke-test","roomId":"voice_room_smoke"}')
check "POST /api/trtc/usersig" "200" "$code"

# YouTube stream — 200 veya 404 (deploy öncesi 404 normal)
code=$(curl -s -o /dev/null -w "%{http_code}" \
  "$BASE/api/chat/youtube-stream?videoId=dQw4w9WgXcQ")
check "GET /api/chat/youtube-stream" "200|404" "$code"

if [[ "$AUTH_FLAG" == "--auth" && -n "${CANLIFAL_JWT:-}" ]]; then
  code=$(curl -s -o /dev/null -w "%{http_code}" \
    "$BASE/api/music/search?q=test" \
    -H "Authorization: Bearer $CANLIFAL_JWT")
  check "GET /api/music/search (JWT)" "200|503" "$code"

  body=$(curl -s "$BASE/api/music/search?q=istanbul" \
    -H "Authorization: Bearer $CANLIFAL_JWT")
  if echo "$body" | grep -q '"items"'; then
    echo "OK   müzik yanıtı items alanı içeriyor"
    pass=$((pass + 1))
  else
    echo "FAIL müzik yanıtında items yok: ${body:0:120}"
    fail=$((fail + 1))
  fi
fi

echo "=== Sonuç: $pass OK, $fail FAIL ==="
[[ "$fail" -eq 0 ]]
