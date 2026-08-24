#!/usr/bin/env bash
# Üretimde jeton kazanım yollarını dener — test hesabı için tanı raporu.
# Jeton yalnızca admin top-up ile artıyorsa exit 1 (beklenen).
# Kullanım: bash scripts/probe-jeton-earn.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults

echo "=== Jeton kazanım probe — $BASE ==="
echo "Hesap: $DEFAULT_ACCEPTANCE_USER_EMAIL"
echo ""

if ! bootstrap_user_token; then
  echo "❌ Giriş başarısız"
  exit 2
fi

jeton_before=$(user_jeton_balance_from_me "$USER_TOKEN")
credits_before=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('credits', 0))
" 2>/dev/null || echo "?")

echo "Başlangıç: jeton=$jeton_before credits=$credits_before"
echo ""

probe_post() {
  local label="$1" url="$2" body="${3:-{}}"
  local resp code
  resp=$(curl -sS -w "\n%{http_code}" -X POST "$url" \
    -H "Authorization: Bearer $USER_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$body" 2>/dev/null || true)
  code=$(printf '%s' "$resp" | tail -1)
  body_out=$(printf '%s' "$resp" | sed '$d' | head -c 160)
  echo "  POST $label → HTTP $code — $body_out"
}

probe_get() {
  local label="$1" url="$2"
  local resp code
  resp=$(curl -sS -w "\n%{http_code}" "$url" \
    -H "Authorization: Bearer $USER_TOKEN" 2>/dev/null || true)
  code=$(printf '%s' "$resp" | tail -1)
  body_out=$(printf '%s' "$resp" | sed '$d' | head -c 160)
  echo "  GET  $label → HTTP $code — $body_out"
}

echo "── Denenen uçlar ──"
probe_post "daily-login" "$BASE/api/daily-login" '{}'
probe_post "jeton daily_login" "$BASE/api/jeton" '{"action":"daily_login"}'
probe_post "daily-spin" "$BASE/api/games/daily-spin" '{}'
probe_post "daily-reward" "$BASE/api/games/daily-reward" '{}'
probe_post "watch-ad" "$BASE/api/user/watch-ad" '{}'
probe_get "jeton catalog" "$BASE/api/jeton"
probe_get "daily-missions" "$BASE/api/daily-missions"

echo ""
jeton_after=$(user_jeton_balance_from_me "$USER_TOKEN")
credits_after=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $USER_TOKEN" | python3 -c "
import json,sys
d=json.load(sys.stdin)
print(d.get('credits', 0))
" 2>/dev/null || echo "?")

echo "Sonuç: jeton $jeton_before→$jeton_after | credits $credits_before→$credits_after"
echo ""

if [[ "$jeton_after" -ge 10 ]]; then
  echo "✅ Jeton yeterli — bash scripts/m7-on-jeton.sh"
  exit 0
fi

if [[ "$jeton_after" -gt "$jeton_before" ]]; then
  echo "⚠️  Jeton arttı ama <10 — bash scripts/wait-for-jeton.sh"
  exit 0
fi

echo "⛔ Otomatik jeton kazanımı yok — admin panel veya ACCEPTANCE_ADMIN_*"
echo "   Rehber: docs/M5_M7_JETON_BLOCKER.md"
exit 1
