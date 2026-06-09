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
  local ok=0
  if [[ "$actual" == "$expected" ]]; then
    ok=1
  elif [[ "$expected" == *"|"* ]]; then
    local part
    IFS='|' read -ra _codes <<< "$expected"
    for part in "${_codes[@]}"; do
      if [[ "$actual" == "$part" ]]; then
        ok=1
        break
      fi
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

echo "=== Parite smoke test: $BASE ==="

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
check "GET /api/chat/youtube-stream" "200|401|404" "$code"

# Oda arka plan kataloğu — 200 veya 404 (Flutter statik fallback kullanır)
code=$(curl -s -o /dev/null -w "%{http_code}" \
  "$BASE/api/chat/rooms/backgrounds")
check "GET /api/chat/rooms/backgrounds" "200|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" \
  "$BASE/images/voice-bg-1.jpg")
check "GET /images/voice-bg-1.jpg" "200" "$code"

# FCM kayıt — 401 (deploy+auth) veya 404 (henüz yok)
code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/devices/fcm" \
  -H "Content-Type: application/json" \
  -d '{"token":"smoke-test-token-0123456789"}')
check "POST /api/devices/fcm" "200|401|404" "$code"

# PK + üyelik — 404 deploy öncesi normal
code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/pk/history")
check "GET /api/pk/history" "200|404" "$code"

code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/api/membership/packages")
check "GET /api/membership/packages" "200|401|404" "$code"

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
    echo "FAIL müzik yanıtında items yok"
    fail=$((fail + 1))
  fi
fi

echo "=== Sonuç: $pass OK, $fail FAIL ==="
[[ "$fail" -eq 0 ]]
