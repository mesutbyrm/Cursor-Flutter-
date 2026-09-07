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
  1) bash scripts/release-remaining-status.sh   # canlı durum
  2) bash scripts/psychic-p0-prereqs.sh         # jeton + falcı uyarısı
  3) bash scripts/list-production-tellers.sh    # üretim falcı listesi
  4) bash scripts/psychic-p0-all.sh             # P0 checklist (2 telefon)
  5) bash scripts/p1-platform-checklist.sh    # P0 PASS sonrası
  6) bash scripts/record-user-test-result.sh p0 PASS
  7) bash scripts/on-p0-pass.sh              # P0 PASS → P1 checklist
  8) bash scripts/on-p1-pass.sh              # P1 PASS → RELEASE adayı

Rehberler:
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
  list)
    exec bash "$ROOT/scripts/list-production-tellers.sh"
    ;;
  closure|agent)
    exec bash "$ROOT/scripts/agent-closure-status.sh"
    ;;
  record)
    shift
    exec bash "$ROOT/scripts/record-user-test-result.sh" "$@"
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
