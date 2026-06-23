#!/usr/bin/env bash
# FAZ 1 — canlı falcı davet push teşhis betiği (üretim API)
#
# Kullanım:
#   export CANLIFAL_BASE="https://canlifal.com"
#   export ADMIN_EMAIL="admin@..."
#   export ADMIN_PASSWORD="..."
#   export TELLER_EMAIL="suna61722@gmail.com"   # İlhamperisi
#   export TELLER_PASSWORD="..."
#   bash scripts/faz1-psychic-invite-probe.sh
#
# Çıktı: docs/FAZ1_LAST_PROBE.json (son çalıştırma özeti)

set -euo pipefail

BASE="${CANLIFAL_BASE:-https://canlifal.com}"
ADMIN_EMAIL="${ADMIN_EMAIL:-}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-}"
TELLER_EMAIL="${TELLER_EMAIL:-suna61722@gmail.com}"
TELLER_PASSWORD="${TELLER_PASSWORD:-}"
OUT="${FAZ1_PROBE_OUT:-docs/FAZ1_LAST_PROBE.json}"
ILHAM_TELLER_ID="${ILHAM_TELLER_ID:-cmokzl5u900w2od09rpqq2fs9}"
ILHAM_USER_ID="${ILHAM_USER_ID:-cmoks76yf00c4ph08ppcoqg98}"
DURATION="${SESSION_DURATION_MINUTES:-10}"

json_field() {
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d$1)" 2>/dev/null || echo ""
}

login() {
  local email="$1" pass="$2"
  curl -sS -X POST "$BASE/api/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$email\",\"password\":\"$pass\"}"
}

echo "=== FAZ 1 Psychic Invite Probe ==="
echo "Base: $BASE"
echo ""

REPORT=$(mktemp)
echo '{}' > "$REPORT"

if [[ -z "$ADMIN_EMAIL" || -z "$ADMIN_PASSWORD" ]]; then
  echo "UYARI: ADMIN_EMAIL / ADMIN_PASSWORD tanımlı değil — yalnızca herkese açık uçlar test edilecek."
fi

# 1) Üretim falcı listesi
TELLERS=$(curl -sS "$BASE/api/fortune-tellers")
echo "$TELLERS" | python3 -c "
import json,sys
d=json.load(sys.stdin)
t=d.get('tellers') or d.get('data',{}).get('tellers') or []
ilham=[x for x in t if x.get('userId')=='$ILHAM_USER_ID' or x.get('id')=='$ILHAM_TELLER_ID']
print('İlhamperisi üretim:', json.dumps(ilham[0] if ilham else {}, ensure_ascii=False))
"

# 2) Admin giriş + randevu
ADMIN_TOKEN=""
SESSION_ID=""
CREATE_HTTP=""
if [[ -n "$ADMIN_EMAIL" && -n "$ADMIN_PASSWORD" ]]; then
  ADMIN_RESP=$(login "$ADMIN_EMAIL" "$ADMIN_PASSWORD")
  ADMIN_TOKEN=$(echo "$ADMIN_RESP" | json_field "['accessToken']")
  if [[ -z "$ADMIN_TOKEN" ]]; then
    ADMIN_TOKEN=$(echo "$ADMIN_RESP" | json_field "['token']")
  fi
  echo "Admin token: ${ADMIN_TOKEN:0:12}..."

  CREATE_RESP=$(curl -sS -w "\nHTTP:%{http_code}" -X POST "$BASE/api/fortune-tellers/session" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
      \"tellerId\": \"$ILHAM_TELLER_ID\",
      \"tellerUserId\": \"$ILHAM_USER_ID\",
      \"clientName\": \"FAZ1 Admin Test\",
      \"durationMinutes\": $DURATION
    }")
  CREATE_HTTP=$(echo "$CREATE_RESP" | tail -1 | sed 's/HTTP://')
  CREATE_BODY=$(echo "$CREATE_RESP" | sed '$d')
  SESSION_ID=$(echo "$CREATE_BODY" | json_field "['sessionId']")
  if [[ -z "$SESSION_ID" ]]; then
    SESSION_ID=$(echo "$CREATE_BODY" | json_field "['session','id']")
  fi
  echo "POST /fortune-tellers/session → HTTP $CREATE_HTTP sessionId=$SESSION_ID"
  echo "$CREATE_BODY" | head -c 800
  echo ""
fi

# 3) İlhamperisi giriş + /api/me + pending
TELLER_TOKEN=""
TELLER_ME=""
PENDING_COUNT=""
if [[ -n "$TELLER_PASSWORD" ]]; then
  TELLER_RESP=$(login "$TELLER_EMAIL" "$TELLER_PASSWORD")
  TELLER_TOKEN=$(echo "$TELLER_RESP" | json_field "['accessToken']")
  if [[ -z "$TELLER_TOKEN" ]]; then
    TELLER_TOKEN=$(echo "$TELLER_RESP" | json_field "['token']")
  fi
  echo "Teller token: ${TELLER_TOKEN:0:12}..."

  TELLER_ME=$(curl -sS "$BASE/api/me" -H "Authorization: Bearer $TELLER_TOKEN")
  echo "/api/me (teller):"
  echo "$TELLER_ME" | head -c 600
  echo ""

  PENDING=$(curl -sS "$BASE/api/fortune-tellers/sessions?status=pending" \
    -H "Authorization: Bearer $TELLER_TOKEN")
  PENDING_COUNT=$(echo "$PENDING" | python3 -c "
import json,sys
d=json.load(sys.stdin)
items=d.get('sessions') or d.get('data',{}).get('sessions') or d.get('items') or []
print(len(items))
" 2>/dev/null || echo "?")
  echo "Pending sessions count: $PENDING_COUNT"
fi

# 4) Özet JSON
python3 - "$OUT" <<PY
import json, os
out = {
  "base": os.environ.get("BASE", "$BASE"),
  "ilhamTellerId": "$ILHAM_TELLER_ID",
  "ilhamUserId": "$ILHAM_USER_ID",
  "adminLoginOk": bool("${ADMIN_TOKEN}"),
  "tellerLoginOk": bool("${TELLER_TOKEN}"),
  "createSessionHttp": "${CREATE_HTTP:-skipped}",
  "sessionId": "${SESSION_ID:-}",
  "pendingCountAfterCreate": "${PENDING_COUNT:-}",
  "createNotification": "sunucu tarafı — üretim log / DB appNotification satırı gerekir",
  "oneSignalApiCalled": "createNotification userId doluysa sendOneSignalToUser çağrılır (api/src/lib/notifications.ts)",
  "oneSignal200": "sunucu log: [createNotification] OneSignal ok status=200",
  "pushReachedPhone": "fiziksel cihaz + OneSignal dashboard / uygulama teşhis kartı ile doğrulanır",
  "notes": [
    "Mobil filtre: evaluatePsychicIncomingInvite — Falcı Paneli teşhis kartı",
    "Kök neden A: nested user.userId → clientId (düzeltildi)",
    "Kök neden B: approvedPsychicProvider gecikmesi + minimal push",
    "Kök neden C: OneSignal foreground preventDefault — filtre red ederse tray yok"
  ]
}
with open("$OUT", "w", encoding="utf-8") as f:
  json.dump(out, f, ensure_ascii=False, indent=2)
print("Wrote", "$OUT")
PY

echo ""
echo "=== FAZ 1 Probe tamamlandı ==="
