#!/usr/bin/env bash
# main → GitHub push; APK + PR temizliği iş akışları otomatik tetiklenir.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if ! command -v gh >/dev/null 2>&1; then
  echo "HATA: gh CLI yok."
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  if [[ -z "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
    echo "HATA: GitHub oturumu yok."
    echo "Cursor → Settings → GitHub → depoyu yeniden bağlayın, sonra bu betiği tekrar çalıştırın."
    exit 1
  fi
  export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
fi

git checkout main
echo "→ origin/main ile senkron..."
git fetch origin main
if git rev-parse --verify origin/main >/dev/null 2>&1; then
  git pull --rebase origin main
fi
echo "→ push..."
git push origin main

echo ""
echo "✓ Push tamam. Otomatik işler:"
echo "  • Build release APK  → apk-latest güncellenir"
echo "  • GitHub cleanup     → eski PR'lar kapanır, cursor/* dalları silinir"
echo ""
gh run list --workflow=build-apk.yml --limit 3 2>/dev/null || true
gh run list --workflow=github-cleanup.yml --limit 3 2>/dev/null || true
