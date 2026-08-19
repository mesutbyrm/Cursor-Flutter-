#!/usr/bin/env bash
# M5 cihaz testi öncesi tüm otomatik kapılar (jeton hariç).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAIL=0

run() {
  local name="$1"
  shift
  echo ""
  echo "── $name ──"
  if "$@"; then
    echo "✅ $name"
  else
    echo "❌ $name"
    FAIL=$((FAIL + 1))
  fi
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  M5 hazır — otomatik kapılar"
echo "╚══════════════════════════════════════════════════════════╝"

run "FAZ12 otomatik" bash "$ROOT/scripts/faz12-automated-gates.sh"
run "m5-preflight" bash "$ROOT/scripts/m5-preflight.sh" || true

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "✅ Otomatik kapılar geçti — cihaz: docs/M5_DEVICE_TEST_CHECKLIST.md"
  exit 0
fi
echo "⚠️  Bazı kapılar başarısız (jeton=0 m5-preflight beklenen)"
exit 1
