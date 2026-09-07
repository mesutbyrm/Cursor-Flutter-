#!/usr/bin/env bash
# Play Console yükleme günü — P0+P1 PASS sonrası adım adım.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

VERSION="?"
if [[ -f "$ROOT/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

p0=0 p1=0
[[ -f "$LOG" ]] && device_test_log_has_pass "Psychic P0" "$LOG" && p0=1
[[ -f "$LOG" ]] && device_test_log_has_pass "P1 Platform" "$LOG" && p1=1

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Play Store yükleme günü (${VERSION})                             ║
╚══════════════════════════════════════════════════════════════════╝

Önkoşul:
  Psychic P0 PASS: $([ "$p0" -eq 1 ] && echo '✅' || echo '⏳ kayıt yok')
  P1 Platform PASS: $([ "$p1" -eq 1 ] && echo '✅' || echo '⏳ kayıt yok')

── 1) Release AAB ──
  [ ] GitHub Secrets: ANDROID_KEYSTORE_* (+ opsiyonel GOOGLE_SERVICES_JSON_BASE64)
  [ ] Actions → Build release AAB → artifact: canlifal-release-aab
      bash scripts/print-ci-aab-steps.sh
      bash scripts/play-keystore-secrets-cheatsheet.sh

── 2) Play Console formları ──
  [ ] App access          → bash scripts/print-play-console-app-access.sh
  [ ] Data safety         → bash scripts/print-play-data-safety-summary.sh
  [ ] Foreground service  → bash scripts/print-play-foreground-service-declaration.sh
  [ ] Content rating      → bash scripts/print-play-content-rating-summary.sh
  [ ] Target audience/Ads → bash scripts/print-play-target-audience-summary.sh
  [ ] Store listing       → bash scripts/print-play-store-listing.sh

── 3) Yükleme ──
  [ ] Closed test track → AAB yükle
  [ ] Testers davet (cursor.test.* / cursor.host.*)
  [ ] 14 gün closed test → Production access başvurusu

Tam checklist: bash scripts/play-store-checklist.sh
Engeller:      bash scripts/print-release-blockers.sh
Rehber:        docs/P2_PLAY_STORE_START.md
EOF
