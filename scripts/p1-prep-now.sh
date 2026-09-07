#!/usr/bin/env bash
# P1 checklist — P0 sonucu beklenmeden yazdır (cihaz testi sonra).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "ℹ️  P0 sonucu sonra kaydedilecek — checklist şimdiden hazırlanabilir."
echo ""

bash "$ROOT/scripts/p1-platform-checklist.sh" --prep

cat <<'EOF'

── P0 sonucu gelince ──
  bash scripts/on-p0-pass.sh
  bash scripts/record-user-test-result.sh p0 PASS

── P1 bittikten sonra ──
  bash scripts/on-p1-pass.sh

Müzik (M5): docs/M5_DEVICE_TEST_CHECKLIST.md · bash scripts/m5-device-prep.sh
EOF
