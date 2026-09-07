#!/usr/bin/env bash
# Kullanıcı devir teslimi — agent prep ✅ tamam, kalan adımlar sizde.
# Kullanım: bash scripts/user-handoff.sh  (= basla.sh)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/print-p0-live-status.sh"

cat <<'EOF'

╔══════════════════════════════════════════════════════════════════╗
║  Devir teslim — agent prep ✅ · kalan adımlar sizde               ║
╚══════════════════════════════════════════════════════════════════╝

Agent: kod · CI · API · falcı · P2 prep betikleri ✅ TAMAM
Siz: cihaz P0→P1 · keystore · Play Console yükleme

── ★ Başlangıç ──
  bash scripts/kullanici-sonraki.sh
  bash scripts/agent-prep-tamam.sh
  bash scripts/print-release-blockers.sh

── Cihaz (sonra) ──
  bash scripts/cihaz-sonra.sh
  bash scripts/p0-go.sh → user-test-start.sh p0

── Play (P0+P1 PASS sonrası) ──
  bash scripts/print-play-upload-day-checklist.sh
  bash scripts/print-ci-aab-steps.sh

Rehber: docs/RELEASE_USER_NEXT_STEPS.md · docs/KALAN_ISLER.md

EOF

bash "$ROOT/scripts/print-build-status.sh" 2>/dev/null | head -8 || true
