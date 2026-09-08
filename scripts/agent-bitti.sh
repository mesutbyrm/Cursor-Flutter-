#!/usr/bin/env bash
# Agent işi bitti — hızlı durum (prep ✅ · kullanıcı adımları).
# Kullanım: bash scripts/agent-bitti.sh [--api]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

run_api=0
for arg in "$@"; do
  case "$arg" in
    --api) run_api=1 ;;
  esac
done

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Agent ✅ BİTTİ — sırada kullanıcı adımları (${VERSION})          ║
╚══════════════════════════════════════════════════════════════════╝

APK: ${APK_URL}
Mobil kod değişmedi → yeni APK beklenmiyor (doc/betik commitleri hariç)

EOF

echo "── Canlı API + falcı ──"
bash "$ROOT/scripts/psychic-p0-prereqs.sh" 2>&1 | tail -8
echo ""
bash "$ROOT/scripts/print-p0-live-status.sh" 2>&1 | grep -E 'APK CI|Gate 3|jeton=' || true
echo ""

if [[ "$run_api" -eq 1 ]]; then
  echo "── API otomasyon (--api) ──"
  bash "$ROOT/scripts/run-api-automation-summary.sh" 2>&1 | tail -14
  echo ""
fi

bash "$ROOT/scripts/agent-prep-tamam.sh" 2>&1 | tail -5
echo ""
bash "$ROOT/scripts/print-release-blockers.sh" 2>&1

cat <<'EOF'

── Sizin sıra ──
  bash scripts/kullanici-sonraki.sh

Tam agent yenileme (yavaş, ~1 dk): bash scripts/devam-et.sh --full
API rapor yenile:                  bash scripts/devam-et.sh --api
Doc sürüm hizala:                  bash scripts/sync-docs-release-header.sh
EOF
