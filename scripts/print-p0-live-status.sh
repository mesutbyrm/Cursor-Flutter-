#!/usr/bin/env bash
# P0 cihaz testi — tek ekran canlı durum (jeton + falcı + APK).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

# shellcheck source=acceptance-tests/defaults.sh
source "$ROOT/scripts/acceptance-tests/defaults.sh"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults
USER_EMAIL="${ACCEPTANCE_USER_EMAIL:-$DEFAULT_ACCEPTANCE_USER_EMAIL}"
USER_PASSWORD="${ACCEPTANCE_USER_PASSWORD:-$DEFAULT_ACCEPTANCE_USER_PASSWORD}"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P0 canlı durum (${VERSION})                                      ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "APK: $APK_URL"
echo "RELEASE READY: NO (Psychic P0 cihaz bekliyor)"
echo ""

# APK
code=$(curl -sS -o /dev/null -w '%{http_code}' -L "$APK_URL" || echo "000")
if [[ "$code" == "200" ]]; then
  echo "✅ APK HTTP 200"
else
  echo "❌ APK HTTP $code"
fi

# Danışan + jeton
if bootstrap_user_token; then
  jeton=$(user_jeton_balance_from_me "$USER_TOKEN" 2>/dev/null || echo "?")
  echo "✅ Danışan jeton=$jeton"
  if [[ "$jeton" =~ ^[0-9]+$ ]] && [[ "$jeton" -lt 100 ]]; then
    echo "⚠️  Jeton düşük — admin panel gerekli"
  fi
else
  echo "❌ Danışan girişi başarısız"
fi

# Falcı probe (kısa)
echo ""
PROBE=$("$ROOT/scripts/probe-psychic-teller.sh" 2>&1 || true)
echo "$PROBE" | grep -E '^(✅|⚠️|❌|──|Falcı probe)' || true

echo ""
echo "── Hesaplar ──"
echo "  Danışan: cursor.test.1786235468@mailinator.com"
echo "  Falcı:   cursor.host.1786235468@mailinator.com"
echo "  Şifre:   CursorTest!1786235468"
echo ""
echo "── Sonraki ──"
echo "  bash scripts/basla.sh"
echo "  bash scripts/p0-go.sh"
echo "  bash scripts/user-test-start.sh p0"
echo "  Sonuç: bash scripts/on-p0-pass.sh | on-p0-fail.sh"
