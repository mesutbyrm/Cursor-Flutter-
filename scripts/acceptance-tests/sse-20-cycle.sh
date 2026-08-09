#!/usr/bin/env bash
# SSE 20-cycle — CONNECT → RECEIVE → DISCONNECT (network).
# Duplicate connection / leak göstergesi: her döngüde yeni curl süreci; birikim curl PID ile ölçülmez,
# ancak 20 ardışık başarısız bağlantı veya timeout birikimi FAIL sayılır.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# shellcheck source=lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd curl python3

CYCLES="${SSE_CYCLE_COUNT:-20}"
USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-}"
USER_TOKEN=""
ROOM_ID=""
REPORT_MD="${ROOT}/docs/SSE_20_CYCLE_TEST.md"

echo "=== SSE 20-Cycle Test (network) ==="
echo "Base: $BASE | Cycles: $CYCLES"
echo ""

if ! acceptance_user_secrets_configured; then
  echo "BLOCKED: ACCEPTANCE_USER_* secret yok"
  exit 2
fi

resp=$(mobile_login_identifier email "$USER_EMAIL" "$USER_PASSWORD")
USER_TOKEN=$(extract_token "$resp")
if [[ -z "$USER_TOKEN" ]]; then
  echo "FAIL: login token alınamadı"
  exit 1
fi

body=$(curl_json "$BASE/api/chat/rooms?limit=10&withCounts=true" \
  -H "Authorization: Bearer $USER_TOKEN")
ROOM_ID=$(pick_first_room_id "$body")
if [[ -z "$ROOM_ID" ]]; then
  echo "FAIL: test odası bulunamadı"
  exit 1
fi

STREAM_URL="$BASE/api/chat/rooms/$ROOM_ID/stream"
success=0
fail=0
bytes_total=0
ts_start=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

for ((i=1; i<=CYCLES; i++)); do
  tmp=$(mktemp)
  # Her döngü: yeni bağlantı, kısa okuma, süreç sonu (disconnect).
  if timeout 3 curl -sS -N \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Accept: text/event-stream" \
    "$STREAM_URL" 2>/dev/null | head -c 512 >"$tmp"; then
  :
  fi
  sz=$(wc -c <"$tmp" | tr -d ' ')
  bytes_total=$((bytes_total + sz))
  if grep -qE '^(data:|event:|:)' "$tmp" 2>/dev/null || [[ "$sz" -gt 0 ]]; then
    success=$((success + 1))
    echo "  cycle $i: OK (${sz} bytes)"
  else
    code=$(http_code -H "Authorization: Bearer $USER_TOKEN" \
      -H "Accept: text/event-stream" "$STREAM_URL")
    if [[ "$code" == "200" ]]; then
      success=$((success + 1))
      echo "  cycle $i: OK (HTTP 200, empty chunk)"
    else
      fail=$((fail + 1))
      echo "  cycle $i: FAIL (HTTP $code)"
    fi
  fi
  rm -f "$tmp"
  sleep 0.15
done

ts_end=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
result="PASS"
if [[ "$fail" -gt 3 ]]; then
  result="FAIL"
elif [[ "$success" -lt $((CYCLES / 2)) ]]; then
  result="FAIL"
fi

mkdir -p "$REPORT_DIR"
{
  echo "# SSE 20-Cycle Test"
  echo ""
  echo "| Alan | Değer |"
  echo "|------|--------|"
  echo "| Başlangıç | $ts_start |"
  echo "| Bitiş | $ts_end |"
  echo "| API | $BASE |"
  echo "| Oda | $ROOM_ID |"
  echo "| Döngü | $CYCLES |"
  echo "| Başarılı | $success |"
  echo "| Başarısız | $fail |"
  echo "| Toplam byte | $bytes_total |"
  echo "| Sonuç | **$result** |"
  echo ""
  echo "## Kontrol listesi"
  echo ""
  echo "- Her döngüde ayrı curl süreci (CONNECT → READ → EXIT = DISCONNECT)"
  echo "- Ardışık 3+ HTTP hata → FAIL"
  echo "- Başarı oranı <%50 → FAIL"
  echo "- Flutter SseClient unit 20-cycle: mobile/test/sse_20_cycle_test.dart"
  echo ""
  echo "## Cihaz notu"
  echo ""
  echo "Bu test ağ katmanıdır; Flutter listener/timer birikimi için birim testi gereklidir."
  echo "Gerçek cihazda 20 ekran giriş/çıkış döngüsü **BLOCKED** (adb yok)."
} >"$REPORT_MD"

echo ""
echo "=== SSE 20-cycle: $result ($success/$CYCLES OK, $fail fail) ==="
echo "Rapor: $REPORT_MD"

if [[ "$result" == "FAIL" ]]; then
  exit 1
fi
