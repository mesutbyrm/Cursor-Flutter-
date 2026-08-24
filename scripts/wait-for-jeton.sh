#!/usr/bin/env bash
# Jeton ≥ hedef olana kadar bekler, sonra M7 + m5-preflight çalıştırır.
# Kullanım: bash scripts/wait-for-jeton.sh [hedef=10] [timeout_s=3600]
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

TARGET="${1:-10}"
TIMEOUT="${2:-3600}"
INTERVAL="${WAIT_JETON_INTERVAL:-30}"

apply_acceptance_credential_defaults

echo "=== wait-for-jeton (hedef≥$TARGET, timeout=${TIMEOUT}s) ==="
echo "Hesap: $DEFAULT_ACCEPTANCE_USER_EMAIL"
echo "Admin: https://canlifal.com/admin → Kullanıcılar → jeton ≥$TARGET"
echo "Alternatif: ACCEPTANCE_ADMIN_EMAIL + ACCEPTANCE_ADMIN_PASSWORD (CI secret)"
echo ""

# İlk turda otomatik kazanım yollarını dene (credits-only beklenir).
bash "$ROOT/scripts/probe-jeton-earn.sh" 2>/dev/null || true
echo ""

start=$(date +%s)
while true; do
  now=$(date +%s)
  if (( now - start >= TIMEOUT )); then
    echo "⏱ Zaman aşımı — jeton hâlâ < $TARGET"
    bash "$ROOT/scripts/faz0-status.sh" | tail -12
    exit 2
  fi

  if bootstrap_user_token 2>/dev/null; then
    J=$(user_jeton_balance_from_me "$USER_TOKEN")
    # Admin secret varsa her turda top-up dene
    if [[ "$J" -lt "$TARGET" ]] && acceptance_admin_secrets_configured 2>/dev/null; then
      USER_ID=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('id') or d.get('user',{}).get('id') or '')
" 2>/dev/null || echo "")
      if [[ -n "$USER_ID" ]]; then
        ensure_test_jeton_minimum "$USER_TOKEN" "$USER_ID" "$USER_EMAIL" "$TARGET" wait-for-jeton >/dev/null 2>&1 || true
        J=$(user_jeton_balance_from_me "$USER_TOKEN")
      fi
    fi
    echo "$(date -u +%H:%M:%S) jeton=$J"
    if [[ "$J" -ge "$TARGET" ]]; then
      echo ""
      echo "✅ jeton=$J — M7 probe başlıyor"
      bash "$ROOT/scripts/m7-on-jeton.sh"
      echo ""
      bash "$ROOT/scripts/m5-preflight.sh"
      echo ""
      echo "Sonraki: docs/M5_DEVICE_TEST_CHECKLIST.md"
      exit 0
    fi
  fi

  unset USER_TOKEN
  sleep "$INTERVAL"
done
