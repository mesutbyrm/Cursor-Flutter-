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
    warn=$((warn + 1))
  else
    echo "✅ Danışan jeton=$jeton"
    ok=$((ok + 1))
  fi
else
  echo "❌ Danışan girişi başarısız"
fi

if bootstrap_host_token; then
  echo "✅ Falcı/host girişi OK ($HOST_EMAIL)"
  ok=$((ok + 1))
else
  echo "❌ Falcı/host girişi başarısız"
fi

echo ""
echo "── Sonraki adım (2 telefon) ──"
echo "  bash scripts/psychic-p0-checklist.sh"
echo "  bash scripts/user-handoff.sh"
echo ""
if [[ "$warn" -gt 0 ]]; then
  echo "Jeton düşükse seans oluşturulamaz; önce admin jeton, sonra P0."
  exit 0
fi
echo "Önkoşullar hazır — cihaz testine geçilebilir."
