#!/usr/bin/env bash
# Kullanıcı devir teslimi — Psychic P0 öncelik (agent işi bitti).
# Kullanım: bash scripts/user-handoff.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/print-p0-live-status.sh"

cat <<'EOF'

╔══════════════════════════════════════════════════════════════════╗
║  Devir teslim — agent tamam, cihaz sizde                         ║
╚══════════════════════════════════════════════════════════════════╝

Agent: kod · CI · API (M5/M7/Gate 3) · falcı onayı ✅
Siz: Psychic P0 — 2 telefon · T+5s donma yok

── Başla (önerilen) ──
  bash scripts/kalan-isler.sh
  bash scripts/p0-go.sh
  bash scripts/user-test-start.sh p0

── Doğrulama (isteğe bağlı) ──
  bash scripts/validate-pre-device-handoff.sh
  bash scripts/user-test-start.sh ready

── Sonuç ──
  PASS → bash scripts/on-p0-pass.sh
  FAIL → bash scripts/on-p0-fail.sh "hangi adım"

── P0 PASS sonrası ──
  bash scripts/p1-go.sh
  bash scripts/on-p1-pass.sh
  bash scripts/on-release-ready-candidate.sh

Rehberler:
  docs/KALAN_ISLER.md
  docs/USER_TEST_QUICK_REF.md
  docs/RELEASE_USER_NEXT_STEPS.md

EOF

bash "$ROOT/scripts/print-build-status.sh" 2>/dev/null | head -12
