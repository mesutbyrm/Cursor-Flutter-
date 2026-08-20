#!/usr/bin/env bash
# FAZ 0 eksikler — sırayla otomatik dene, her adımda tamamlanan/kalan yazdır.
# Kullanım: bash scripts/faz0-sequential.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

REPORT="${ROOT}/docs/FAZ0_SEQUENTIAL_PROGRESS.md"
VERSION=$(grep -E '^version:' "$ROOT/mobile/pubspec.yaml" | awk '{print $2}')
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")

DONE=()
BLOCKED=()
PENDING=()
STEP=0

mark_done() { DONE+=("$1"); echo "  ✅ BİTTİ: $1"; }
mark_blocked() { BLOCKED+=("$1"); echo "  ⏸️  BLOKE: $1"; }
mark_pending() { PENDING+=("$1"); echo "  ⬜ KALAN: $1"; }

run_step() {
  local title="$1"
  shift
  STEP=$((STEP + 1))
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " ADIM $STEP — $title"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  if "$@"; then
    return 0
  fi
  return 1
}

show_remaining() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║  ÖZET — tamamlanan: ${#DONE[@]}  bloke: ${#BLOCKED[@]}  kalan: ${#PENDING[@]}"
  echo "╚══════════════════════════════════════════════════════════╝"
  if [[ ${#DONE[@]} -gt 0 ]]; then
    echo ""
    echo "✅ Tamamlanan (${#DONE[@]}):"
    for x in "${DONE[@]}"; do echo "   • $x"; done
  fi
  if [[ ${#BLOCKED[@]} -gt 0 ]]; then
    echo ""
    echo "⏸️  Bloke — sizin aksiyonunuz (${#BLOCKED[@]}):"
    for x in "${BLOCKED[@]}"; do echo "   • $x"; done
  fi
  if [[ ${#PENDING[@]} -gt 0 ]]; then
    echo ""
    echo "⬜ Sıradaki / bekleyen (${#PENDING[@]}):"
    for x in "${PENDING[@]}"; do echo "   • $x"; done
  fi
  echo ""
}

write_report() {
  mkdir -p "$(dirname "$REPORT")"
  {
    echo "# FAZ 0 — Sıralı ilerleme"
    echo ""
    echo "**Tarih:** $UTC  "
    echo "**APK:** \`$VERSION\`"
    echo ""
    echo "## Tamamlanan (${#DONE[@]})"
    echo ""
    for x in "${DONE[@]}"; do echo "- [x] $x"; done
    echo ""
    echo "## Bloke — kullanıcı (${#BLOCKED[@]})"
    echo ""
    for x in "${BLOCKED[@]}"; do echo "- [ ] $x"; done
    echo ""
    echo "## Kalan (${#PENDING[@]})"
    echo ""
    for x in "${PENDING[@]}"; do echo "- [ ] $x"; done
    echo ""
    echo "Yenile: \`bash scripts/faz0-sequential.sh\`"
  } >"$REPORT"
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  FAZ 0 sıralı eksikler — $VERSION"
echo "╚══════════════════════════════════════════════════════════╝"

# ── A. Otomatik kapılar ─────────────────────────────────────

run_step "15 faz unit testi" bash "$ROOT/scripts/run-phase-tests.sh" && \
  mark_done "FAZ1–11 faz testleri (15 PASS)" || mark_blocked "Faz testleri başarısız"

run_step "voice_hub unit (113+)" \
  bash -c 'cd "'"$ROOT"'/mobile" && flutter test test/features/voice_hub/ --reporter compact' && \
  mark_done "voice_hub unit testleri" || mark_blocked "voice_hub testleri başarısız"

run_step "API müzik kabul" bash "$ROOT/scripts/run-music-acceptance.sh" && \
  mark_done "API müzik 6/6 + M7 probe" || mark_blocked "API müzik başarısız"

run_step "API voice seat (jeton yok)" bash "$ROOT/scripts/run-voice-seat-acceptance.sh" && \
  mark_done "API voice seat (presence/koltuk/SSE)" || mark_blocked "API voice seat başarısız"

run_step "FAZ12 otomatik kapılar" bash "$ROOT/scripts/faz12-automated-gates.sh" && \
  mark_done "FAZ12 otomatik 4/4" || mark_blocked "FAZ12 kapıları başarısız"

run_step "FAZ11 güvenlik taraması" bash "$ROOT/scripts/faz11-security-scan.sh" && \
  mark_done "FAZ11 security scan" || mark_blocked "FAZ11 scan başarısız"

run_step "MCP selftest" bash -c 'cd "'"$ROOT"'/mcp-server" && node index.mjs --selftest' && \
  mark_done "MCP selftest v1.2.0" || mark_blocked "MCP selftest başarısız"

show_remaining

# ── B. Jeton ────────────────────────────────────────────────

apply_acceptance_credential_defaults
JETON=0
if bootstrap_user_token 2>/dev/null; then
  JETON=$(user_jeton_balance_from_me "$USER_TOKEN")
fi

run_step "Jeton bakiyesi (hedef ≥10)" bash -c '[[ '"$JETON"' -ge 10 ]]' && \
  mark_done "Jeton yeterli (jeton=$JETON)" || {
  if acceptance_admin_secrets_configured; then
    mark_blocked "Jeton=$JETON — admin top-up denendi ama yetersiz"
  else
    mark_blocked "Jeton=$JETON — admin panelden ≥50 jeton ekleyin (ACCEPTANCE_ADMIN_* yok)"
  fi
  mark_pending "M7 song-request HTTP 200 (jeton gerekli)"
  mark_pending "m5-preflight tam geçiş (jeton gerekli)"
  mark_pending "M5 cihaz Test 1–3 müzik/!istek"
}

show_remaining

# ── C. M7 (jeton varsa) ─────────────────────────────────────

if [[ "$JETON" -ge 10 ]]; then
  run_step "M7 song-request HTTP 200" bash "$ROOT/scripts/m7-on-jeton.sh" && \
    mark_done "M7 song-request HTTP 200" || mark_blocked "M7 probe başarısız"
  run_step "M5 API smoke (Test 1–4)" bash "$ROOT/scripts/m5-api-smoke.sh" && \
    mark_done "M5 API smoke (song-request, presence, SSE)" || mark_blocked "M5 API smoke başarısız"
  run_step "m5-preflight" bash "$ROOT/scripts/m5-preflight.sh" && \
    mark_done "m5-preflight tam geçti" || mark_blocked "m5-preflight başarısız"
else
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " ADIM $((STEP + 1)) — M7 + m5-preflight (atlandı — jeton yok)"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  ⏭️  jeton=$JETON < 10"
fi

show_remaining

# ── D. M5 cihaz (manuel) ────────────────────────────────────

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " ADIM $((STEP + 2)) — M5 Android cihaz (10 test)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
mark_blocked "M5 cihaz — docs/M5_DEVICE_TEST_CHECKLIST.md (Test 1–10)"
mark_pending "A9 FAZ 0 kapat — M5 PASS sonrası"

show_remaining
write_report

echo "Rapor: docs/FAZ0_SEQUENTIAL_PROGRESS.md"
echo ""

if [[ ${#BLOCKED[@]} -gt 0 && "$JETON" -lt 10 ]]; then
  echo "👉 Sıradaki sizin adımınız: https://canlifal.com/admin → jeton ≥50"
  echo "   Sonra: bash scripts/after-admin-jeton.sh"
  exit 1
fi
exit 0
