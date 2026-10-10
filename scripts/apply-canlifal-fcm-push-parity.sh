#!/usr/bin/env bash
# canlifal.com (mesutbyrm/canlifal) nextjs_space — FCM push parity dosyalarını kopyalar.
# Agent bu repoya push edemez; siz full-source dalında commit + deploy edin.
#
# Kullanım:
#   bash scripts/apply-canlifal-fcm-push-parity.sh /path/to/canlifal
#
# Sonra notify.ts: doğrudan OneSignal yerine @/lib/push sendPush kullanın (aşağıdaki not).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/backend-parity/nextjs_space"
DEST_ROOT="${1:-}"

if [[ -z "$DEST_ROOT" ]]; then
  echo "Hedef canlifal repo kökü gerekli (içinde nextjs_space/ olmalı)."
  echo "Örnek: bash scripts/apply-canlifal-fcm-push-parity.sh ../canlifal"
  exit 1
fi

NS="$DEST_ROOT/nextjs_space"
if [[ ! -d "$NS" ]]; then
  echo "Bulunamadı: $NS"
  exit 1
fi

copy() {
  local rel="$1"
  local from="$SRC/$rel"
  local to="$NS/$rel"
  if [[ ! -f "$from" ]]; then
    echo "Kaynak yok: $from"
    exit 1
  fi
  mkdir -p "$(dirname "$to")"
  cp -v "$from" "$to"
}

echo "=== FCM push parity → $NS ==="
copy lib/fcm-push.ts
copy lib/push.ts
copy lib/push-test.ts
copy app/api/notifications/test-push/route.ts

echo ""
echo "=== notify.ts (elle) ==="
echo "nextjs_space/lib/notify.ts içinde sendPushToUser (onesignal) çağrılarını"
echo "  import { sendPush } from '@/lib/push'"
echo "ile değiştirin; payload: title, body, type, targetPath?, targetId?, urgent?"
echo ""
echo "=== Deploy env ==="
echo "  PUSH_PROVIDER=fcm"
echo "  GOOGLE_APPLICATION_CREDENTIALS=/path/to/canlifal-firebase-adminsdk.json"
echo "  ONESIGNAL_SEND_DISABLED=1"
echo ""
echo "Rehber: docs/FCM_BACKEND_DEPLOY_FCM_ONLY.md · docs/FCM_CANLIFAL_PR_PATCH.md"
