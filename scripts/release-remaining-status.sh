#!/usr/bin/env bash
# Kalan release işleri — canlı durum (P0-j, P0, P1, P2).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Canlifal — kalan release işleri (${VERSION})                     ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# --- P0-j: jeton ---
echo "── P0-j · Danışan jeton (bloker) ──"
PREREQ=$("$ROOT/scripts/psychic-p0-prereqs.sh" 2>&1) || true
echo "$PREREQ" | grep -E '^(✅|⚠️|❌)' || true
if echo "$PREREQ" | grep -q 'jeton=0'; then
  echo "Durum: ❌ OPEN — admin panel veya ACCEPTANCE_ADMIN_* secret"
  echo "  bash scripts/admin-jeton-cheatsheet.sh"
  echo "  docs/M5_M7_JETON_BLOCKER.md"
  P0J="OPEN"
else
  echo "Durum: ✅ jeton yeterli görünüyor"
  P0J="OK"
fi
echo ""

# --- P0: Psychic TRTC ---
echo "── P0 · Psychic TRTC 2-cihaz (T+5s donma) ──"
if [[ "$P0J" == "OPEN" ]]; then
  echo "Durum: ⏸ BEKLEMEDE — önce P0-j (jeton)"
else
  echo "Durum: ⏳ OPEN — 2 telefon manuel test"
fi
echo "  bash scripts/psychic-p0-all.sh"
echo "  docs/PSYCHIC_P0_START.md"
echo "  Sonuç: Psychic P0 PASS veya FAIL"
echo ""

# --- P1 ---
echo "── P1 · Genel platform 2-cihaz (P0 sonrası) ──"
echo "Durum: ⏸ P0 PASS sonrası"
echo "  bash scripts/p1-platform-checklist.sh"
echo "  docs/P1_DEVICE_START.md"
echo "  docs/M5_DEVICE_TEST_CHECKLIST.md (müzik/voice)"
echo ""

# --- P2 ---
echo "── P2 · Play Store / Stage 8 ──"
echo "Durum: ⏸ backlog"
echo "  docs/PLAY_STORE_PRODUCTION_ACCESS.md"
echo "  docs/STAGE8_FINAL_ACCEPTANCE_REPORT.md"
echo ""

# --- Agent ---
echo "── Agent ──"
echo "Kod/CI/docs: ✅ TAMAM · RELEASE READY: NO"
echo "APK: ${APK_URL}"
echo ""
echo "Sonraki adım:"
if [[ "$P0J" == "OPEN" ]]; then
  echo "  1) Admin jeton → bash scripts/psychic-p0-all.sh"
else
  echo "  1) bash scripts/psychic-p0-all.sh (2 telefon)"
fi
