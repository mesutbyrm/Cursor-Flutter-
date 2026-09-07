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

Sıra: P0-j ✅ · cihaz testi **SONRA** · agent P1/P2 prep **ŞİMDİ**

★ ÖNERİLEN:
  bash scripts/kalan-isler-agent.sh            # agent paralel (cihaz sonra)
  bash scripts/cihaz-sonra.sh                  # cihaz testi (sonuç sonra)

Komutlar:
  0) bash scripts/kalan-isler-agent.sh         # agent · şimdi
  1) bash scripts/cihaz-sonra.sh               # cihaz · sonra
  2) bash scripts/p2-prep-all.sh               # Play Store hazırlık (tam)
  3) bash scripts/p1-prep-now.sh               # P1 checklist ön
  4) bash scripts/basla.sh                     # canlı durum
  5) bash scripts/p0-go.sh
  6) bash scripts/validate-pre-device-handoff.sh
  7) bash scripts/user-test-start.sh p0
  8) bash scripts/on-p0-pass.sh | on-p0-fail.sh
  9) bash scripts/p1-go.sh
 10) bash scripts/on-p1-pass.sh
 11) bash scripts/p2-go.sh
 12) bash scripts/on-release-ready-candidate.sh
 13) bash scripts/psychic-p0-prereqs.sh
 14) bash scripts/probe-psychic-teller.sh
 15) bash scripts/open-approved-teller.sh
 16) bash scripts/run-non-device-release-prep.sh

Rehberler:
  docs/KALAN_ISLER.md               ← kalan işler (statik özet)
  docs/USER_TEST_QUICK_REF.md       ← 1 sayfa özet
  docs/RELEASE_USER_NEXT_STEPS.md   ← paralel mod, tek sayfa
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
  agent|kalan-agent|agent-kalan)
    exec bash "$ROOT/scripts/kalan-isler-agent.sh"
    ;;
  cihaz-sonra|later|sonra)
    exec bash "$ROOT/scripts/cihaz-sonra.sh"
    ;;
  p1-prep|p1prep)
    exec bash "$ROOT/scripts/p1-prep-now.sh"
    ;;
  p2-prep|p2prep)
    exec bash "$ROOT/scripts/p2-prep-now.sh"
    ;;
  p2-prep-all|p2all)
    exec bash "$ROOT/scripts/p2-prep-all.sh"
    ;;
  fgs|foreground|play-fgs)
    exec bash "$ROOT/scripts/print-play-foreground-service-declaration.sh"
    ;;
  data-safety|play-data)
    exec bash "$ROOT/scripts/print-play-data-safety-summary.sh"
    ;;
  play-checklist|play-store)
    exec bash "$ROOT/scripts/play-store-checklist.sh"
    ;;
  keystore|secrets)
    exec bash "$ROOT/scripts/play-keystore-secrets-cheatsheet.sh"
    ;;
  app-access|play-access)
    exec bash "$ROOT/scripts/print-play-console-app-access.sh"
    ;;
  aab-ready|aab-readiness)
    exec bash "$ROOT/scripts/play-aab-readiness.sh"
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
