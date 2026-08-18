#!/usr/bin/env bash
# ACCEPTANCE_* secret doğrulama — üretim API giriş testi (secret değerlerini yazdırmaz).
# Kullanım:
#   export ACCEPTANCE_ADMIN_EMAIL=... ACCEPTANCE_ADMIN_PASSWORD=...
#   bash scripts/validate-acceptance-secrets.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults

FAIL=0
PASS=0
WARN=0

check_login() {
  local label="$1" kind="$2" id="$3" pass="$4"
  local resp tok
  if [[ -z "$id" || -z "$pass" ]]; then
    echo "⏭️  $label — secret yok"
    WARN=$((WARN + 1))
    return 0
  fi
  if [[ "$kind" == email ]]; then
    resp=$(mobile_login_identifier email "$id" "$pass")
  else
    resp=$(mobile_login_identifier username "$id" "$pass")
  fi
  tok=$(extract_token "$resp")
  if [[ -n "$tok" ]]; then
    echo "✅ $label — giriş OK"
    PASS=$((PASS + 1))
    return 0
  fi
  echo "❌ $label — giriş başarısız"
  FAIL=$((FAIL + 1))
  return 1
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Acceptance secret doğrulama (canlifal.com)              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo "API: $BASE"
echo ""

echo "── Kullanıcı (TEST_USER) ──"
if check_login "USER email" email "${ACCEPTANCE_USER_EMAIL:-}" "${ACCEPTANCE_USER_PASSWORD:-}"; then
  : # ok
elif [[ -n "${ACCEPTANCE_USER_USERNAME:-}" && -n "${ACCEPTANCE_USER_PASSWORD:-}" ]]; then
  check_login "USER username" username "$ACCEPTANCE_USER_USERNAME" "$ACCEPTANCE_USER_PASSWORD" || true
fi
if [[ -z "${ACCEPTANCE_USER_EMAIL:-}" && -z "${ACCEPTANCE_USER_USERNAME:-}" ]]; then
  echo "   Varsayılan: $DEFAULT_ACCEPTANCE_USER_EMAIL"
  check_login "USER (varsayılan)" email "$DEFAULT_ACCEPTANCE_USER_EMAIL" "$DEFAULT_ACCEPTANCE_USER_PASSWORD" || true
fi
echo ""

echo "── Host (TEST_LIVE_HOST) ──"
if [[ -n "${ACCEPTANCE_HOST_EMAIL:-}" && -n "${ACCEPTANCE_HOST_PASSWORD:-}" ]]; then
  check_login "HOST email" email "$ACCEPTANCE_HOST_EMAIL" "$ACCEPTANCE_HOST_PASSWORD" || true
else
  echo "⏭️  HOST — secret yok (varsayılan kullanılır)"
  WARN=$((WARN + 1))
fi
echo ""

echo "── Admin (jeton top-up) ──"
ADMIN_OK=0
if [[ -n "${ACCEPTANCE_ADMIN_EMAIL:-}" && -n "${ACCEPTANCE_ADMIN_PASSWORD:-}" ]]; then
  if check_login "ADMIN email" email "$ACCEPTANCE_ADMIN_EMAIL" "$ACCEPTANCE_ADMIN_PASSWORD"; then
    ADMIN_OK=1
  fi
fi
if [[ "$ADMIN_OK" -eq 0 && -n "${ACCEPTANCE_ADMIN_USERNAME:-}" && -n "${ACCEPTANCE_ADMIN_PASSWORD:-}" ]]; then
  if check_login "ADMIN username" username "$ACCEPTANCE_ADMIN_USERNAME" "$ACCEPTANCE_ADMIN_PASSWORD"; then
    ADMIN_OK=1
  fi
fi
if [[ "$ADMIN_OK" -eq 0 && ! acceptance_admin_secrets_configured ]]; then
  echo "⏭️  ADMIN — secret yok (manuel jeton gerekli)"
  WARN=$((WARN + 1))
fi
echo ""

echo "── Jeton (varsayılan test hesabı) ──"
if bootstrap_user_token 2>/dev/null; then
  J=$(user_jeton_balance_from_me "$USER_TOKEN")
  echo "Hesap: $USER_EMAIL — jeton=$J"
  if [[ "$J" -ge 10 ]]; then
    echo "✅ Jeton yeterli — bash scripts/m7-on-jeton.sh"
    PASS=$((PASS + 1))
  else
    echo "⚠️  jeton < 10 — M5/M7 bekliyor"
    WARN=$((WARN + 1))
  fi
else
  echo "❌ Varsayılan test girişi başarısız"
  FAIL=$((FAIL + 1))
fi
echo ""

echo "══════════════════════════════════════════════════════════"
echo "Sonuç: PASS=$PASS WARN=$WARN FAIL=$FAIL"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "Düzeltme:"
  echo "  1. USER/HOST: bash scripts/set-acceptance-secrets.sh"
  echo "  2. ADMIN: gh secret set ACCEPTANCE_ADMIN_EMAIL --repo <repo>"
  echo "  3. Manuel jeton: docs/M5_M7_JETON_BLOCKER.md"
  exit 1
fi
exit 0
