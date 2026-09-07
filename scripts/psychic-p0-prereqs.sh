#!/usr/bin/env bash
# Psychic P0 önkoşul kontrolü — APK, giriş, jeton uyarısı (cihaz testi öncesi).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

# shellcheck source=acceptance-tests/defaults.sh
source "$ROOT/scripts/acceptance-tests/defaults.sh"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

require_cmd curl python3

USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-$DEFAULT_ACCEPTANCE_USER_EMAIL}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-$DEFAULT_ACCEPTANCE_USER_PASSWORD}"
HOST_EMAIL="${ACCEPTANCE_HOST_EMAIL:-$DEFAULT_ACCEPTANCE_HOST_EMAIL}"
HOST_PASSWORD="${ACCEPTANCE_HOST_PASSWORD:-$DEFAULT_ACCEPTANCE_HOST_PASSWORD}"

echo "=== Psychic P0 önkoşullar ==="
echo ""

ok=0
warn=0
jeton_warn=0
teller_warn=0

# APK HTTP
code=$(curl -sS -o /dev/null -w '%{http_code}' -L "$APK_URL" || echo "000")
if [[ "$code" == "200" ]]; then
  echo "✅ APK indirme HTTP 200"
  ok=$((ok + 1))
else
  echo "❌ APK HTTP $code — $APK_URL"
fi

# Login
if bootstrap_user_token; then
  echo "✅ Danışan girişi OK ($USER_EMAIL)"
  ok=$((ok + 1))
  jeton=$(user_jeton_balance_from_me "$USER_TOKEN" 2>/dev/null || echo "?")
  if [[ "$jeton" =~ ^[0-9]+$ ]] && [[ "$jeton" -lt 100 ]]; then
    echo "⚠️  Danışan jeton=$jeton — Psychic seans için admin panelden jeton ekleyin"
    echo "    Rehber: docs/M5_M7_JETON_BLOCKER.md · bash scripts/admin-jeton-cheatsheet.sh"
    jeton_warn=1
    warn=$((warn + 1))
  else
    echo "✅ Danışan jeton=$jeton"
    ok=$((ok + 1))
  fi
else
  echo "❌ Danışan girişi başarısız"
fi

host_ok=0
for host_attempt in 1 2 3; do
  if bootstrap_host_token; then
    host_ok=1
    break
  fi
  if [[ "$host_attempt" -lt 3 ]]; then
    sleep 2
  fi
done
if [[ "$host_ok" -eq 1 ]]; then
  host_me=$(curl_json "$BASE/api/me" -H "Authorization: Bearer $HOST_TOKEN" 2>/dev/null || echo "{}")
  host_email_me=$(printf '%s' "$host_me" | python3 -c "import json,sys; d=json.load(sys.stdin); print((d.get('email') or d.get('user',{}).get('email') or '').lower())" 2>/dev/null || echo "")
  if [[ -n "$host_email_me" && "$host_email_me" != "${HOST_EMAIL,,}" ]]; then
    echo "⚠️  Host token danışan hesabına düşmüş — probe yine de devam eder"
    warn=$((warn + 1))
  else
    echo "✅ Falcı/host girişi OK ($HOST_EMAIL)"
    ok=$((ok + 1))
  fi
else
  echo "❌ Falcı/host girişi başarısız"
fi

echo ""
echo "── Falcı listesi (Psychic seans) ──"
if [[ -x "${ROOT}/scripts/probe-psychic-teller.sh" ]]; then
  # Önkoşulda zaten host oturumu var — subprocess'e aktar (çift login / rate limit).
  [[ -n "${HOST_TOKEN:-}" ]] && export HOST_TOKEN
  if [[ -z "${HOST_TOKEN:-}" ]]; then
    sleep 2
  fi
  PROBE=$("${ROOT}/scripts/probe-psychic-teller.sh" 2>&1 || true)
  echo "$PROBE" | grep -E '^(──|✅|⚠️|❌|  |Falcı probe)' || true
  if echo "$PROBE" | grep -q 'Falcı listesinde DEĞİL'; then
    teller_warn=1
    warn=$((warn + 1))
  elif echo "$PROBE" | grep -q 'Falcı probe: listede'; then
    : # OK
  elif echo "$PROBE" | grep -qE 'giriş hatası|Host girişi başarısız|ACCEPTANCE_TELLER girişi başarısız'; then
    teller_warn=1
    warn=$((warn + 1))
  fi
fi

echo ""
echo "── Sonraki adım (2 telefon) ──"
echo "  bash scripts/basla.sh"
echo "  bash scripts/p0-go.sh"
echo "  bash scripts/user-test-start.sh p0"
echo ""
if [[ "$jeton_warn" -gt 0 ]]; then
  echo "Jeton düşük — seans oluşturulamaz; önce admin jeton, sonra P0."
  exit 0
fi
if [[ "$teller_warn" -gt 0 ]]; then
  echo "Falcı uyarısı — onaylı falcı hesabı ile P0 deneyin veya probe tekrarlayın."
  echo "  bash scripts/probe-psychic-teller.sh"
  echo "  docs/PSYCHIC_TELLER_STATUS.md · bash scripts/open-approved-teller.sh"
  exit 0
fi
echo "Önkoşullar hazır — cihaz testine geçilebilir."
