#!/usr/bin/env bash
# Release gate öncesi hızlı giriş doğrulaması — CI'da anlaşılır hata mesajı.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/acceptance-tests/lib.sh"

apply_acceptance_credential_defaults

echo "=== Acceptance preflight ==="
echo "API: $BASE"
echo "User: $USER_EMAIL (@$USER_USERNAME)"
echo "Host: $HOST_EMAIL"
echo ""

# API erişilebilirlik — takılmayı önle (http_code: connect 10s / max 60s).
api_code=$(http_code "$BASE/api/me" 2>/dev/null || echo "000")
if [[ "$api_code" == "000" ]]; then
  echo "❌ API erişilemedi (timeout veya bağlantı hatası): $BASE"
  echo "   Kontrol: API_BASE_URL, canlifal.com erişimi, firewall."
  exit 1
fi
echo "✅ API erişilebilir (HTTP $api_code /api/me)"

# Secret env özeti (değerler loglanmaz).
for label_var in \
  "ACCEPTANCE_USER_EMAIL:ACCEPTANCE_USER_EMAIL" \
  "ACCEPTANCE_USER_PASSWORD:ACCEPTANCE_USER_PASSWORD" \
  "ACCEPTANCE_USER_USERNAME:ACCEPTANCE_USER_USERNAME" \
  "ACCEPTANCE_HOST_EMAIL:ACCEPTANCE_HOST_EMAIL" \
  "ACCEPTANCE_ADMIN_EMAIL:ACCEPTANCE_ADMIN_EMAIL" \
  "ACCEPTANCE_TELLER_EMAIL:ACCEPTANCE_TELLER_EMAIL"; do
  label="${label_var%%:*}"
  var="${label_var##*:}"
  if [[ -n "${!var:-}" ]]; then
    echo "  secret $label: set"
  else
    echo "  secret $label: (boş — varsayılan veya SKIP)"
  fi
done
echo ""

if bootstrap_user_token; then
  echo "✅ Kullanıcı girişi OK"
else
  echo "❌ Kullanıcı girişi başarısız"
  echo ""
  echo "GitHub Secrets güncelleyin veya yerelde:"
  echo "  bash scripts/set-acceptance-secrets.sh"
  echo "Detay: docs/ACCEPTANCE_TESTS.md"
  exit 1
fi

if bootstrap_host_token; then
  echo "✅ Host girişi OK"
else
  echo "⚠️  Host girişi başarısız (canlı yayın testi etkilenebilir)"
fi

echo ""
echo "Preflight geçti — release gate devam edebilir."
