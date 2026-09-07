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
echo "$PREREQ" | grep -E '^(✅|⚠️|❌).*(APK|Danışan|jeton|Falcı/host)' || true
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
elif [[ -x "${ROOT}/scripts/probe-psychic-teller.sh" ]]; then
  PROBE_LINE=$("${ROOT}/scripts/probe-psychic-teller.sh" 2>&1 | grep -E 'Falcı listesinde|Falcı probe:' | head -1 || true)
  if echo "$PROBE_LINE" | grep -qE 'Falcı listesinde|listede —'; then
    echo "Durum: ⏳ OPEN — 2 telefon manuel test (host falcı listede ✅)"
  elif echo "$PROBE_LINE" | grep -q 'DEĞİL'; then
    echo "Durum: ⏳ OPEN — 2 telefon (⚠️ falcı listede değil — bash scripts/open-approved-teller.sh)"
  else
    echo "Durum: ⏳ OPEN — 2 telefon manuel test"
  fi
else
  echo "Durum: ⏳ OPEN — 2 telefon manuel test"
fi
echo "  bash scripts/p0-go.sh"
echo "  bash scripts/user-test-start.sh p0"
echo "  bash scripts/validate-pre-device-handoff.sh"
echo "  bash scripts/probe-psychic-teller.sh"
echo "  docs/RELEASE_USER_NEXT_STEPS.md"
echo "  Sonuç: bash scripts/on-p0-pass.sh | on-p0-fail.sh"
echo ""

# --- API automation ---
echo "── Otomatik API (jeton sonrası) ──"
if [[ -f "${ROOT}/docs/M7_MUSIC_SSE_CAPTURE.md" ]] && grep -q 'HTTP 200' "${ROOT}/docs/M7_MUSIC_SSE_CAPTURE.md" 2>/dev/null; then
  echo "  M7 song-request: ✅ HTTP 200 (M7_MUSIC_SSE_CAPTURE.md)"
else
  echo "  M7: bash scripts/m7-on-jeton.sh"
fi
if [[ -f "${ROOT}/docs/M5_API_SMOKE_REPORT.md" ]] && grep -qE 'PASS=6|\| 6 \| 2 \| 0 \|' "${ROOT}/docs/M5_API_SMOKE_REPORT.md" 2>/dev/null; then
  echo "  M5 API smoke: ✅ PASS=6 SKIP=2"
else
  echo "  M5: bash scripts/m5-api-smoke.sh"
fi
if [[ -f "${ROOT}/docs/ACCEPTANCE_TEST_REPORT.md" ]] && grep -qE '\| 3 \|.*PASS' "${ROOT}/docs/ACCEPTANCE_TEST_REPORT.md" 2>/dev/null; then
  echo "  API Gate 3 (Psychic): ✅ PASS (session + TRTC)"
else
  echo "  Gate 3: bash scripts/acceptance-tests/api-release-gate.sh"
fi
echo "  Özet: bash scripts/run-api-automation-summary.sh"
echo ""

# --- P1 ---
echo "── P1 · Platform 2-cihaz (voice/gift/PK/müzik) ──"
echo "Durum: ⏸ P0 PASS sonrası"
echo "  bash scripts/p1-go.sh"
echo "  bash scripts/p1-platform-checklist.sh"
echo "  docs/P1_DEVICE_START.md"
echo "  docs/M5_DEVICE_TEST_CHECKLIST.md (müzik/voice)"
echo ""

# --- P2 ---
echo "── P2 · Play Store / Stage 8 ──"
echo "Durum: ⏸ backlog (P0+P1 sonrası)"
echo "  bash scripts/p2-go.sh"
echo "  docs/P2_PLAY_STORE_START.md"
echo "  docs/PLAY_STORE_PRODUCTION_ACCESS.md"
echo "  docs/STAGE8_FINAL_ACCEPTANCE_REPORT.md"
echo ""

# --- Agent ---
echo "── Agent ──"
echo "Kod/CI/docs: ✅ TAMAM · RELEASE READY: NO"
echo "Canlı durum: bash scripts/kalan-isler.sh"
echo "Hızlı özet: bash scripts/print-user-test-quick-ref.sh"
echo "APK: ${APK_URL}"
echo ""
echo "Sonraki adım:"
if [[ "$P0J" == "OPEN" ]]; then
  echo "  1) Admin jeton → bash scripts/user-test-start.sh"
else
  echo "  1) bash scripts/p0-go.sh  (veya: user-test-start.sh p0)"
  echo "  2) Doğrulama: bash scripts/validate-pre-device-handoff.sh"
  echo "  3) Sonuç: bash scripts/on-p0-pass.sh  veya  on-p0-fail.sh"
fi
