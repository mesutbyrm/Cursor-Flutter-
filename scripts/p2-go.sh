#!/usr/bin/env bash
# P2 — GO ekranı: P0+P1 PASS sonrası Play Store / AAB backlog.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="${ROOT}/docs/USER_DEVICE_TEST_LOG.md"
# shellcheck source=device-test-log-lib.sh
source "$ROOT/scripts/device-test-log-lib.sh"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  P2 GO — Play Store / Stage 8 (${VERSION})                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

p0_ok=0 p1_ok=0
if device_test_log_has_pass "Psychic P0" "$LOG"; then
  echo "✅ Psychic P0 PASS kaydı var"
  p0_ok=1
else
  echo "⏳ Psychic P0 PASS yok — önce: bash scripts/on-p0-pass.sh"
fi
if device_test_log_has_pass "P1 Platform" "$LOG"; then
  echo "✅ P1 Platform PASS kaydı var"
  p1_ok=1
else
  echo "⏸ P1 PASS yok — P0 sonrası: bash scripts/on-p1-pass.sh"
fi
echo ""

bash "$ROOT/scripts/print-ci-aab-steps.sh" 2>&1 | head -14

cat <<'EOF'

── Play Console (kullanıcı) ──
  docs/PLAY_STORE_PRODUCTION_ACCESS.md
  docs/P2_PLAY_STORE_START.md

Test hesapları (Play Console App Access):
  Danışan: cursor.test.1786235468@mailinator.com
  Host:    cursor.host.1786235468@mailinator.com

EOF

if [[ "$p0_ok" -eq 1 && "$p1_ok" -eq 1 ]]; then
  echo "✅ P0+P1 PASS — RELEASE adayı kontrol listesi:"
  echo "   bash scripts/on-release-ready-candidate.sh"
  echo "   bash scripts/print-ci-aab-steps.sh"
  echo "   bash scripts/build-play-aab.sh   # CI keystore secret gerekir"
else
  echo "Agent prep (şimdi): bash scripts/p2-prep-go.sh"
  echo "Önce cihaz testleri: bash scripts/cihaz-sonra.sh"
fi
