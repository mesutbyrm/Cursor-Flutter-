#!/usr/bin/env bash
# Cihaz testi öncesi otomatik doğrulama (API + jeton + falcı uyarısı).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Pre-device handoff — otomatik doğrulama                          ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

fail=0

run_step() {
  local name="$1" cmd="$2"
  echo "── $name ──"
  if eval "$cmd"; then
    echo ""
  else
    echo "⚠️  $name — uyarı veya kısmi başarısızlık"
    fail=$((fail + 1))
    echo ""
  fi
}

run_step "Durum özeti" "bash '$ROOT/scripts/release-remaining-status.sh'"
run_step "P0 önkoşullar" "bash '$ROOT/scripts/psychic-p0-prereqs.sh'" || true

echo "── API otomasyon (M5/M7) ──"
if bash "$ROOT/scripts/run-api-automation-summary.sh" 2>&1 | tail -12; then
  echo ""
else
  fail=$((fail + 1))
fi

echo "══════════════════════════════════════════════════════════════════"
if [[ "$fail" -eq 0 ]]; then
  echo "✅ Otomatik doğrulama tamam — cihaz testine geçilebilir"
else
  echo "⚠️  Bazı adımlarda uyarı var — yine de P0 denenebilir (falcı hesabına dikkat)"
fi
echo ""
echo "Sonraki:"
echo "  Agent (şimdi): bash scripts/devam-et.sh"
echo "  P2 prep:       bash scripts/p2-prep-go.sh"
echo "  Cihaz (sonra): bash scripts/cihaz-sonra.sh"
echo "  bash scripts/basla.sh"
echo "  bash scripts/kalan-isler.sh"
echo "  bash scripts/p0-go.sh"
echo "  docs/RELEASE_USER_NEXT_STEPS.md"
exit 0
