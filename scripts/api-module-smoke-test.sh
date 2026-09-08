#!/usr/bin/env bash
# Modül smoke test — Main vs Game backend doğru uçları döndürüyor mu?
set -euo pipefail

MAIN="${CANLIFAL_BASE_URL:-https://canlifal.com}"
GAME="${GAMES_API_BASE_URL:-https://canlifalapi.abacusai.app}"

normalize() {
  local u="${1%/}"
  [[ "$u" == */api ]] && u="${u%/api}"
  printf '%s' "$u"
}
MAIN="$(normalize "$MAIN")"
GAME="$(normalize "$GAME")"

PASS=0
FAIL=0
declare -a FAILURES=()

check() {
  local module="$1" base="$2" path="$3" expect="$4"
  local code
  code=$(curl -sS -o /dev/null -w "%{http_code}" "${base}${path}" 2>/dev/null || echo "000")
  if [[ "$code" == "$expect" ]] || [[ "$expect" == "2xx" && "$code" =~ ^2 ]]; then
    echo "✅ $module — $path → $code ($base)"
    PASS=$((PASS + 1))
  elif [[ "$expect" == "401or404ok" && ( "$code" == "401" || "$code" == "404" ) ]]; then
    echo "✅ $module — $path → $code (auth/endpoint var)"
    PASS=$((PASS + 1))
  elif [[ "$expect" == "not404" && "$code" != "404" ]]; then
    echo "✅ $module — $path → $code ($base)"
    PASS=$((PASS + 1))
  else
    echo "❌ $module — $path beklenen=$expect alınan=$code ($base)"
    FAIL=$((FAIL + 1))
    FAILURES+=("$module|$path|$code|$base")
  fi
}

echo "=== Canlifal Modül Smoke Test ==="
echo "Main: $MAIN"
echo "Game: $GAME"
echo ""

# Main backend modülleri — 404 olmamalı (401/200 kabul)
check "Banner" "$MAIN" "/api/banners" "not404"
check "Ana Sayfa Fal Kartları" "$MAIN" "/api/homepage-fortune-cards" "not404"
check "Sosyal Akış" "$MAIN" "/api/social/posts" "not404"
check "Kısa Videolar" "$MAIN" "/api/shorts" "not404"
check "Falcılar" "$MAIN" "/api/fortune-tellers" "not404"
check "Canlı fal oda" "$MAIN" "/api/room/smoke-test" "401or404ok"
check "Aktif seanslar" "$MAIN" "/api/user/active-sessions" "401or404ok"
code_trtc=$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$MAIN/api/trtc/token" \
  -H "Content-Type: application/json" \
  -d '{"roomId":"smoke","userId":"u1"}' 2>/dev/null || echo "000")
if [[ "$code_trtc" == "200" || "$code_trtc" == "401" || "$code_trtc" == "403" ]]; then
  echo "✅ TRTC token — POST /api/trtc/token → $code_trtc ($MAIN)"
  PASS=$((PASS + 1))
else
  echo "❌ TRTC token — POST /api/trtc/token → $code_trtc ($MAIN)"
  FAIL=$((FAIL + 1))
  FAILURES+=("TRTC token|POST /api/trtc/token|$code_trtc|$MAIN")
fi
check "Sesli Oda Listesi" "$MAIN" "/api/chat/rooms" "not404"
check "Oyun Kataloğu" "$MAIN" "/api/games" "not404"
check "Profil /api/me" "$MAIN" "/api/me" "401or404ok"
check "Jeton" "$MAIN" "/api/user/credits" "401or404ok"
check "Mobil Login" "$MAIN" "/api/auth/mobile-login" "not404"

# Game backend — oda uçları
check "Oyun Odaları Listesi" "$GAME" "/api/games/rooms" "not404"
code_post=$(curl -sS -o /dev/null -w "%{http_code}" -X POST "$GAME/api/games/rooms" \
  -H "Content-Type: application/json" -d '{"gameType":"okey101"}' 2>/dev/null || echo "000")
if [[ "$code_post" != "404" ]]; then
  echo "✅ Okey101 Oda Oluştur — POST → $code_post ($GAME)"
  PASS=$((PASS + 1))
else
  echo "❌ Okey101 Oda Oluştur — POST → 404 ($GAME)"
  FAIL=$((FAIL + 1))
  FAILURES+=("Okey101|POST /api/games/rooms|404|$GAME")
fi

check "Health (Game)" "$GAME" "/api/v1/health" "2xx"

echo ""
echo "=== Özet ==="
echo "Başarılı: $PASS"
echo "Başarısız: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "Başarısız modüller:"
  for f in "${FAILURES[@]}"; do
    IFS='|' read -r mod path code base <<< "$f"
    echo "  - $mod: $path → HTTP $code @ $base"
  done
  exit 1
fi
exit 0
