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

Sıra: P0-j (jeton) ✅ → P0 Psychic → P1 platform → P2 Play Store

Komutlar:
  1) bash scripts/validate-pre-device-handoff.sh  # otomatik doğrulama (API+jeton)
  2) bash scripts/release-remaining-status.sh   # canlı durum
  3) bash scripts/psychic-p0-prereqs.sh         # jeton + falcı uyarısı
  4) bash scripts/list-production-tellers.sh    # üretim falcı listesi
  4b) bash scripts/open-approved-teller.sh      # host → onaylı falcı aç/doğrula
  5) bash scripts/print-p0-live-status.sh     # jeton + falcı (tek ekran)
  6) bash scripts/print-full-user-checklist.sh  # P0+P1 birleşik yazdır
  7) bash scripts/psychic-p0-all.sh             # P0 akışı
  8) bash scripts/p1-platform-checklist.sh    # P0 PASS sonrası
  9) bash scripts/on-p0-pass.sh              # P0 PASS → P1 checklist
 10) bash scripts/on-p0-fail.sh "not"        # P0 FAIL → hotfix kaydı
 11) bash scripts/on-p1-pass.sh              # P1 PASS → RELEASE adayı
 12) bash scripts/on-release-ready-candidate.sh  # P0+P1 sonrası
 13) bash scripts/run-psychic-unit-tests.sh     # Flutter unit (cihaz yok)
 14) bash scripts/p2-play-store-prep.sh          # P2 backlog özeti

Rehberler:
  docs/USER_TEST_QUICK_REF.md       ← 1 sayfa özet
  docs/RELEASE_USER_NEXT_STEPS.md   ← agent kapalı, tek sayfa
  docs/PSYCHIC_P0_START.md
  docs/PSYCHIC_TELLER_STATUS.md   ← host falcı listesinde değilse okuyun
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
  handoff)
    exec bash "$ROOT/scripts/user-handoff.sh"
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
  release-ready|ready)
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
  p2|play-store)
    exec bash "$ROOT/scripts/p2-play-store-prep.sh"
    ;;
  unit|psychic-test)
    exec bash "$ROOT/scripts/run-psychic-unit-tests.sh"
    ;;
  prep|non-device)
    exec bash "$ROOT/scripts/run-non-device-release-prep.sh"
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
