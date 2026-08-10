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
