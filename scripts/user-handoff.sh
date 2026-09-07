#!/usr/bin/env bash
# Kullanıcı devir teslimi — paralel mod (cihaz sonra, agent P2 prep devam).
# Kullanım: bash scripts/user-handoff.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/print-p0-live-status.sh"

cat <<'EOF'

╔══════════════════════════════════════════════════════════════════╗
║  Devir teslim — paralel mod                                       ║
╚══════════════════════════════════════════════════════════════════╝

Agent (şimdi): API ✅ · falcı ✅ · P2 Play Console prep devam
Cihaz (sonra): Psychic P0 → P1 · T+5s donma yok

── Agent (şimdi) ──
  bash scripts/devam-et.sh
  bash scripts/print-paralel-mod.sh
  bash scripts/p1-prep-go.sh
  bash scripts/p2-prep-go.sh
  bash scripts/p2-prep-all.sh

── Cihaz (sonra) ──
  bash scripts/cihaz-sonra.sh
  bash scripts/p0-go.sh
  bash scripts/user-test-start.sh p0

── Sonuç (test bitince) ──
  PASS → bash scripts/on-p0-pass.sh
  FAIL → bash scripts/on-p0-fail.sh "hangi adım"

Rehberler:
  docs/KALAN_ISLER.md
  docs/USER_TEST_QUICK_REF.md
  docs/RELEASE_USER_NEXT_STEPS.md
  docs/PLAY_STORE_AGENT_CHECKLIST.md

EOF

bash "$ROOT/scripts/print-build-status.sh" 2>/dev/null | head -12
