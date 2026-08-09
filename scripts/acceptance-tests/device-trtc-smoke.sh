#!/usr/bin/env bash
# Fiziksel Android cihaz bağlıysa TRTC token + APK yükleme duman testi.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3 adb

echo "=== Cihaz TRTC duman testi ==="

if ! adb devices 2>/dev/null | grep -qE '[[:space:]]device$'; then
  echo "❌ Bağlı Android cihaz yok."
  echo "   Telefonda: Ayarlar → Geliştirici seçenekleri → USB hata ayıklama AÇIK"
  echo "   USB kabloyla bağlayın, sonra: adb devices"
  exit 2
fi

DEVICE=$(adb devices | awk '/device$/{print $1; exit}')
echo "✅ Cihaz: $DEVICE"

bootstrap_user_token || {
  echo "❌ ACCEPTANCE_USER_* secret yok veya giriş başarısız"
  exit 2
}

USER_ID=$(fetch_me_field "$USER_TOKEN" "id")
ROOM_ID="device_smoke_${RUN_ID}"
body=$(curl -sS -X POST "$BASE/api/trtc/token" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"roomId\":\"$ROOM_ID\",\"userId\":\"$USER_ID\",\"role\":\"anchor\"}")

if ! trtc_response_has_sig "$body"; then
  echo "❌ TRTC token alınamadı"
  echo "$body"
  exit 1
fi
echo "✅ TRTC token alındı (room=$ROOM_ID)"

APK_URL="${APK_DOWNLOAD_URL:-https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk}"
APK_LOCAL="/tmp/canlifal-mobile-release.apk"
if [[ ! -f "$APK_LOCAL" ]]; then
  echo "APK indiriliyor..."
  curl -fsSL -o "$APK_LOCAL" "$APK_URL"
fi
adb -s "$DEVICE" install -r "$APK_LOCAL" >/dev/null 2>&1 || adb -s "$DEVICE" install -r "$APK_LOCAL"
echo "✅ APK yüklendi"

echo ""
echo "Manuel adımlar (telefonda):"
echo "  1. Canlifal uygulamasını açın"
echo "  2. Test hesabıyla giriş: $ACCEPTANCE_USER_EMAIL"
echo "  3. Sesli oda veya canlı yayına girin — mikrofon izni verin"
echo "  4. Ses duyuluyorsa TRTC enterRoom başarılı sayılır"
echo ""
echo "API token testi geçti. Ses/kamera için uygulama içi doğrulama gerekir."
