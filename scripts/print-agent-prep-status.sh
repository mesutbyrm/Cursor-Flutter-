#!/usr/bin/env bash
# Agent P2 prep — betik/envanter durumu (cihaz beklemeden).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

exist() {
  [[ -x "$ROOT/scripts/$1" ]] && echo "✅ $1" || echo "❌ $1"
}

VERSION="?"
if [[ -f "$ROOT/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Agent P2 prep durumu (${VERSION})                                ║
╚══════════════════════════════════════════════════════════════════╝

── Giriş betikleri ──
$(exist devam-et.sh)
$(exist p2-prep-go.sh)
$(exist p2-prep-all.sh)
$(exist print-paralel-mod.sh)
$(exist print-release-blockers.sh)
$(exist print-go-commands.sh)

── Play Console print ──
$(exist print-play-console-app-access.sh)
$(exist print-play-foreground-service-declaration.sh)
$(exist print-play-data-safety-summary.sh)
$(exist print-play-content-rating-summary.sh)
$(exist print-play-target-audience-summary.sh)
$(exist print-play-store-listing.sh)
$(exist print-play-upload-day-checklist.sh)
$(exist print-ci-aab-steps.sh)

── CI / imza ──
$(exist play-keystore-secrets-cheatsheet.sh)
$(exist build-play-aab.sh)
$(exist play-aab-readiness.sh)
$([ -f "$ROOT/.github/workflows/build-aab.yml" ] && echo "✅ .github/workflows/build-aab.yml" || echo "❌ build-aab.yml")

── AAB readiness ──
EOF

bash "$ROOT/scripts/play-aab-readiness.sh" 2>&1 | grep -E '^(✅|⏳|===)' | head -12 || true

echo ""
echo "Tam prep:  bash scripts/p2-prep-all.sh"
echo "Yükleme:   bash scripts/print-play-upload-day-checklist.sh"
