#!/usr/bin/env bash
# Aşama 8 — Final otomatik acceptance (API + birim testleri; cihaz gerekmez).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "=== API Final Phase (Aşama 8) ==="
echo "Root: $ROOT"
echo ""

FAIL=0

run_phase() {
  local name="$1"
  local script="$2"
  echo ""
  echo "========== $name =========="
  if bash "$script"; then
    echo "✅ $name OK"
  else
    echo "❌ $name FAIL"
    FAIL=$((FAIL + 1))
  fi
}

run_phase "Release Gate" "$SCRIPT_DIR/api-release-gate.sh"
run_phase "Gift Phase" "$SCRIPT_DIR/api-gift-phase.sh"
run_phase "Music Phase" "$SCRIPT_DIR/api-music-phase.sh"

echo ""
echo "========== Flutter unit tests =========="
if (cd "$ROOT/mobile" && flutter test --reporter compact); then
  echo "✅ Flutter tests OK"
else
  echo "❌ Flutter tests FAIL"
  FAIL=$((FAIL + 1))
fi

echo ""
if [[ "$FAIL" -eq 0 ]]; then
  echo "=== Final API phase: TÜM OTOMATİK KONTROLLER GEÇTİ ==="
  exit 0
fi
echo "=== Final API phase: $FAIL kontrol başarısız ==="
exit 1
