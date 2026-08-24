#!/usr/bin/env bash
# M7 tamamlama — jeton ≥10 olunca song-request 200 + SSE probe çalıştırır.
# Kullanım: bash scripts/m7-on-jeton.sh
# Jeton yoksa: docs/M5_M7_JETON_BLOCKER.md
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults
export MUSIC_PROBE_ROOM="${MUSIC_PROBE_ROOM:-cmoohrbr}"
MIN_JETON="${M7_MIN_JETON:-10}"

echo "=== M7 on-jeton (oda=$MUSIC_PROBE_ROOM, min=$MIN_JETON) ==="

if ! bootstrap_user_token; then
  echo "❌ Giriş başarısız"
  exit 1
fi

USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")

JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
echo "Hesap: $USER_EMAIL — jeton=$JETON"

if [[ "$JETON" -lt "$MIN_JETON" ]]; then
  if acceptance_admin_secrets_configured; then
    echo "Admin top-up deneniyor (hedef=50)..."
    if ensure_test_jeton_minimum "$USER_TOKEN" "$USER_ID" "$USER_EMAIL" 50 m7-on-jeton 2>/dev/null; then
      JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
      echo "✅ Top-up sonrası jeton=$JETON"
    fi
  fi
fi

if [[ "$JETON" -lt "$MIN_JETON" ]]; then
  echo ""
  echo "❌ jeton=$JETON < $MIN_JETON — M7 tamamlanamaz."
  echo "   Rehber: docs/M5_M7_JETON_BLOCKER.md"
  echo "   Durum:  bash scripts/faz0-status.sh"
  exit 2
fi

echo ""
echo "── M7 probe (song-request + SSE) ──"
bash "$ROOT/scripts/probe-music-room.sh"

CAPTURE="$ROOT/docs/M7_MUSIC_SSE_CAPTURE.md"
if grep -q 'HTTP 200' "$CAPTURE" 2>/dev/null; then
  echo ""
  echo "✅ M7: song-request HTTP 200 yakalandı — $CAPTURE"
  echo "   Sonraki: docs/M5_DEVICE_TEST_CHECKLIST.md (M5 cihaz)"
  exit 0
fi

CODE=$(grep -oE 'HTTP [0-9]+' "$CAPTURE" | head -1 | awk '{print $2}' || echo "?")
echo ""
echo "⚠️  Probe bitti ama HTTP 200 yok (HTTP $CODE)."
echo "   Rapor: $CAPTURE"
exit 3
