#!/usr/bin/env bash
# Ana sayfa + kısa video API süre ölçümü (curl).
set -euo pipefail

MAIN="${CANLIFAL_BASE_URL:-https://canlifal.com}"
MAIN="${MAIN%/}"
MAIN="${MAIN%/api}"

measure() {
  local label="$1"
  local url="$2"
  local ms
  ms=$(curl -sS -o /dev/null -w "%{time_total}" "$url" 2>/dev/null || echo "0")
  ms=$(python3 -c "print(int(float('$ms')*1000))")
  printf "| %s | %s | %d |\n" "$label" "$url" "$ms"
}

echo "# Ana sayfa & Shorts API süre raporu"
echo ""
echo "Tarih: $(date -u +"%Y-%m-%d %H:%M UTC")"
echo "Main: $MAIN"
echo ""
echo "| Modül | URL | ms |"
echo "|-------|-----|-----|"

measure "Banner" "$MAIN/api/banners"
measure "Fal kartları" "$MAIN/api/homepage-fortune-cards"
measure "Sosyal" "$MAIN/api/social/posts"
measure "Shorts feed" "$MAIN/api/short-videos?limit=12&tab=foryou"
measure "Shorts explore" "$MAIN/api/short-videos/explore?limit=12"
measure "Canlı yayın" "$MAIN/api/video-streams"
measure "Sesli oda" "$MAIN/api/chat/rooms"
measure "Falcılar" "$MAIN/api/fortune-tellers"
measure "Hikayeler" "$MAIN/api/stories?page=1&limit=30"
measure "Oyun kataloğu" "$MAIN/api/games"

echo ""
echo "_Ölçüm: curl time_total × 1000 — tek istek, önbelleksiz ağ._"
