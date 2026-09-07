#!/usr/bin/env bash
# Agent P2 prep — tamamlandı mı? (betik envanteri doğrulama).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

required=(
  devam-et.sh
  p2-prep-go.sh
  p2-prep-all.sh
  print-play-console-app-access.sh
  print-play-foreground-service-declaration.sh
  print-play-data-safety-summary.sh
  print-play-content-rating-summary.sh
  print-play-target-audience-summary.sh
  print-play-store-listing.sh
  print-play-upload-day-checklist.sh
  print-ci-aab-steps.sh
  print-agent-prep-status.sh
  print-release-blockers.sh
  print-go-commands.sh
  play-keystore-secrets-cheatsheet.sh
  build-play-aab.sh
)

missing=0
for s in "${required[@]}"; do
  if [[ ! -x "$ROOT/scripts/$s" ]]; then
    echo "❌ eksik: scripts/$s"
    missing=$((missing + 1))
  fi
done

if [[ ! -f "$ROOT/.github/workflows/build-aab.yml" ]]; then
  echo "❌ eksik: .github/workflows/build-aab.yml"
  missing=$((missing + 1))
fi

echo ""
bash "$ROOT/scripts/print-agent-prep-status.sh" 2>&1 | tail -8

echo ""
if [[ "$missing" -eq 0 ]]; then
  echo "✅ Agent P2 prep betik paketi TAMAM"
  echo "   Kalan: P0+P1 cihaz + keystore secret + Play Console yükleme"
  echo "   bash scripts/print-release-blockers.sh"
  exit 0
fi

echo "⚠️  $missing eksik betik/dosya — yukarıya bakın"
exit 1
