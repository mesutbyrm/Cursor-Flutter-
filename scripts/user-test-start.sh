#!/usr/bin/env bash
# Kullanıcı cihaz testi — tek giriş noktası (P0 → P1 → durum özeti).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

show_menu() {
  cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Canlifal — cihaz testi başlangıç (${VERSION})                    ║
╚══════════════════════════════════════════════════════════════════╝

APK: ${APK_URL}

Sıra: P0-j ✅ → **P0 OPEN** → P1 → P2

★ ÖNERİLEN (başla):
  bash scripts/basla.sh                       # tek komut: canlı durum + devir teslim
  bash scripts/kalan-isler.sh                 # kalan işler + canlı durum
  bash scripts/p0-go.sh                       # P0 GO (jeton + falcı + hesaplar)

Komutlar:
  0) bash scripts/kalan-isler.sh              # yol haritası (★)
  1) bash scripts/p0-go.sh                    # P0 GO (★)
  2) bash scripts/validate-pre-device-handoff.sh   # user-test-start.sh device-ready
  3) bash scripts/user-test-start.sh p0       # P0 checklist
  4) bash scripts/on-p0-pass.sh | on-p0-fail.sh
  5) bash scripts/p1-go.sh                    # P0 PASS sonrası
  6) bash scripts/p1-platform-checklist.sh
  7) bash scripts/on-p1-pass.sh
  8) bash scripts/p2-go.sh                    # Play Store backlog
  9) bash scripts/on-release-ready-candidate.sh
 10) bash scripts/psychic-p0-prereqs.sh
 11) bash scripts/probe-psychic-teller.sh
 12) bash scripts/open-approved-teller.sh
 13) bash scripts/run-non-device-release-prep.sh

Rehberler:
  docs/KALAN_ISLER.md               ← kalan işler (statik özet)
  docs/USER_TEST_QUICK_REF.md       ← 1 sayfa özet
  docs/RELEASE_USER_NEXT_STEPS.md   ← agent kapalı, tek sayfa
  docs/PSYCHIC_P0_START.md
  docs/PSYCHIC_TELLER_STATUS.md   ← falcı durumu / open-approved-teller
  docs/P1_DEVICE_START.md
  docs/KULLANICI_TEST_KILAVUZU.md

Sonuç bildirimi (tek satır):
  Psychic P0 PASS / FAIL  →  sonra  P1 PASS / FAIL

EOF
}

case "${1:-}" in
  status)
    exec bash "$ROOT/scripts/release-remaining-status.sh"
    ;;
  prereqs)
    exec bash "$ROOT/scripts/psychic-p0-prereqs.sh"
    ;;
  teller)
    exec bash "$ROOT/scripts/probe-psychic-teller.sh"
    ;;
  open-teller|teller-open)
    exec bash "$ROOT/scripts/open-approved-teller.sh"
    ;;
  p0)
    exec bash "$ROOT/scripts/psychic-p0-all.sh"
    ;;
  p0-pass)
    shift
    exec bash "$ROOT/scripts/on-p0-pass.sh" "$@"
    ;;
  p0-fail)
    shift
    exec bash "$ROOT/scripts/on-p0-fail.sh" "$@"
    ;;
  p1-pass)
    shift
    exec bash "$ROOT/scripts/on-p1-pass.sh" "$@"
    ;;
  p1)
    exec bash "$ROOT/scripts/p1-platform-checklist.sh"
    ;;
  p1-go|p1go)
    exec bash "$ROOT/scripts/p1-go.sh"
    ;;
  basla|handoff)
    exec bash "$ROOT/scripts/basla.sh"
    ;;
  api)
    exec bash "$ROOT/scripts/run-api-automation-summary.sh"
    ;;
  list|tellers)
    exec bash "$ROOT/scripts/list-production-tellers.sh"
    ;;
  closure|agent)
    exec bash "$ROOT/scripts/agent-closure-status.sh"
    ;;
  record)
    shift
    exec bash "$ROOT/scripts/record-user-test-result.sh" "$@"
    ;;
  quick|ref)
    exec bash "$ROOT/scripts/print-user-test-quick-ref.sh"
    ;;
  release-ready)
    exec bash "$ROOT/scripts/on-release-ready-candidate.sh"
    ;;
  full|checklist)
    exec bash "$ROOT/scripts/print-full-user-checklist.sh"
    ;;
  validate|check)
    exec bash "$ROOT/scripts/validate-pre-device-handoff.sh"
    ;;
  live|p0-status)
    exec bash "$ROOT/scripts/print-p0-live-status.sh"
    ;;
  ready|p0-ready|device-ready)
    exec bash "$ROOT/scripts/validate-pre-device-handoff.sh"
    ;;
  go|p0-go|start)
    exec bash "$ROOT/scripts/p0-go.sh"
    ;;
  p2|play-store)
    exec bash "$ROOT/scripts/p2-play-store-prep.sh"
    ;;
  unit|psychic-test)
    exec bash "$ROOT/scripts/run-psychic-unit-tests.sh"
    ;;
  prep|non-device)
    exec bash "$ROOT/scripts/run-non-device-release-prep.sh"
    ;;
  kalan|remaining|kalan-isler)
    exec bash "$ROOT/scripts/kalan-isler.sh"
    ;;
  p2-go|p2go)
    exec bash "$ROOT/scripts/p2-go.sh"
    ;;
  ""|help|-h|--help)
    show_menu
    ;;
  *)
    echo "Bilinmeyen alt komut: $1"
    echo ""
    show_menu
    exit 1
    ;;
esac
