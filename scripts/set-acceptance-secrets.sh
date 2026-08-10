#!/usr/bin/env bash
# ACCEPTANCE_* GitHub secrets güncelleme (repo admin gh oturumu gerekir).
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"

# shellcheck source=acceptance-tests/defaults.sh
source "$(cd "$(dirname "$0")" && pwd)/acceptance-tests/defaults.sh"

if ! command -v gh >/dev/null 2>&1; then
  echo "Hata: gh CLI gerekli"
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "Hata: gh oturumu yok. Önce: gh auth login"
  exit 1
fi

if ! gh api "repos/$REPO/actions/secrets/public-key" --silent >/dev/null 2>&1; then
  echo "Hata: GitHub secret yazma izni yok (HTTP 403)."
  echo "Repo admin hesabıyla yerelde çalıştırın:"
  echo "  bash scripts/set-acceptance-secrets.sh"
  echo ""
  echo "Alternatif (GitHub UI): Settings → Secrets and variables → Actions"
  exit 1
fi

set_secret() {
  local name="$1" value="$2"
  printf '%s' "$value" | gh secret set "$name" --repo "$REPO"
  echo "  ✓ $name"
}

echo "Acceptance secrets güncelleniyor: $REPO"
echo ""

set_secret ACCEPTANCE_USER_EMAIL "$DEFAULT_ACCEPTANCE_USER_EMAIL"
set_secret ACCEPTANCE_USER_USERNAME "$DEFAULT_ACCEPTANCE_USER_USERNAME"
set_secret ACCEPTANCE_USER_PASSWORD "$DEFAULT_ACCEPTANCE_USER_PASSWORD"
set_secret ACCEPTANCE_HOST_EMAIL "$DEFAULT_ACCEPTANCE_HOST_EMAIL"
set_secret ACCEPTANCE_HOST_PASSWORD "$DEFAULT_ACCEPTANCE_HOST_PASSWORD"

echo ""
echo "Tamamlandı. Doğrulama:"
echo "  bash scripts/acceptance-preflight.sh"
echo ""
echo "APK derlemesi: Actions → Build release APK → RUN WORKFLOW"
