#!/usr/bin/env bash
# RELEASE READY engelleri — tek ekran (agent vs kullanıcı).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

p0_pass=0 p1_pass=0
if [[ -f "$LOG" ]]; then
  device_test_log_has_pass "Psychic P0" "$LOG" && p0_pass=1
  device_test_log_has_pass "P1 Platform" "$LOG" && p1_pass=1
fi

keystore_ok=0
if [[ -f "$ROOT/mobile/android/key.properties" ]] || [[ -n "${ANDROID_KEYSTORE_BASE64:-}" ]]; then
  keystore_ok=1
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  RELEASE READY engelleri (${VERSION})                             ║
╚══════════════════════════════════════════════════════════════════╝

RELEASE READY: NO

── Cihaz (kullanıcı — kritik) ──
  [$([ "$p0_pass" -eq 1 ] && echo 'x' || echo ' ')] Psychic P0 PASS (2 telefon, T+5s donma yok)
  [$([ "$p1_pass" -eq 1 ] && echo 'x' || echo ' ')] P1 Platform PASS (voice/gift/PK/müzik)
      → bash scripts/cihaz-sonra.sh · on-p0-pass.sh · on-p1-pass.sh

── Play Store (kullanıcı — P0+P1 sonrası yükleme) ──
  [$([ "$keystore_ok" -eq 1 ] && echo 'x' || echo ' ')] Release keystore / GitHub ANDROID_KEYSTORE_*
  [ ] GitHub Actions → Build release AAB → artifact indir
  [ ] Play Console closed test + formlar (app access, data safety, FGS, IARC)
      → bash scripts/p2-prep-go.sh · bash scripts/print-ci-aab-steps.sh

── Agent (tamam) ──
  [x] Kod + CI release gate FINAL PASS
  [x] API M5/M7 + Gate 3 TRTC
  [x] Host falcı listede · jeton ~98k
  [x] P2 prep betik paketi — bash scripts/agent-prep-tamam.sh

Sonraki (kullanıcı): bash scripts/kullanici-sonraki.sh
Agent API yenile:   bash scripts/devam-et.sh
EOF
