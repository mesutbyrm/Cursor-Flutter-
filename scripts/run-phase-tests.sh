#!/usr/bin/env bash
# Faz bazlı Flutter test koşucu — PHASE_PLAN.md ile hizalı.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE="$ROOT/mobile"
REPORT="${PHASE_TEST_REPORT:-$ROOT/docs/PHASE_TEST_REPORT.md}"
UTC=$(date -u +"%Y-%m-%d %H:%M UTC")

declare -A PHASE_DIRS=(
  ["FAZ1"]="test/core test/auth_service_test.dart test/api_response_test.dart test/core/network"
  ["FAZ2"]="test/features/profile"
  ["FAZ3"]="test/features/social test/features/feed"
  ["FAZ4"]="test/features/fortune"
  ["FAZ5"]="test/features/live"
  ["FAZ6"]="test/features/voice_hub"
  ["FAZ7"]="test/features/gifts"
  ["FAZ8"]="test/features/shorts"
  ["FAZ9"]="test/features/messages test/features/notifications test/messages_cache_codec_test.dart"
)

PASS=0
FAIL=0
SKIP=0
LOG=""

run_phase() {
  local name="$1" dirs="$2"
  echo ""
  echo "══ $name ══"
  local any=0
  for d in $dirs; do
    local path="$MOBILE/$d"
    if [[ -e "$path" ]]; then
      any=1
      echo "── $d ──"
      if (cd "$MOBILE" && flutter test "$d" 2>&1); then
        LOG+="| $name | \`$d\` | PASS |\n"
        PASS=$((PASS + 1))
      else
        LOG+="| $name | \`$d\` | FAIL |\n"
        FAIL=$((FAIL + 1))
        return 1
      fi
    fi
  done
  if [[ "$any" -eq 0 ]]; then
    echo "⏭️  test dizini yok"
    LOG+="| $name | — | SKIP (no tests) |\n"
    SKIP=$((SKIP + 1))
  fi
  return 0
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Faz testleri — $UTC"
echo "╚══════════════════════════════════════════════════════════╝"

set +e
for name in FAZ1 FAZ2 FAZ3 FAZ4 FAZ5 FAZ6 FAZ7 FAZ8 FAZ9; do
  run_phase "$name" "${PHASE_DIRS[$name]}" || true
done
set -e

# MCP selftest (FAZ0 tooling)
echo ""
echo "══ MCP (FAZ0) ══"
if (cd "$ROOT/mcp-server" && node index.mjs --selftest >/dev/null 2>&1); then
  LOG+="| FAZ0 | mcp-server selftest | PASS |\n"
  PASS=$((PASS + 1))
else
  LOG+="| FAZ0 | mcp-server selftest | FAIL |\n"
  FAIL=$((FAIL + 1))
fi

{
  echo "# Faz test raporu"
  echo ""
  echo "**Tarih:** $UTC"
  echo ""
  echo "| Geçti | Başarısız | Atlandı |"
  echo "|-------|-----------|---------|"
  echo "| $PASS | $FAIL | $SKIP |"
  echo ""
  echo "## Detay"
  echo ""
  echo "| Faz | Hedef | Sonuç |"
  echo "|-----|-------|--------|"
  printf '%b' "$LOG"
} >"$REPORT"

echo ""
echo "══════════════════════════════════════════════════════════"
echo "Sonuç: PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
echo "Rapor: docs/PHASE_TEST_REPORT.md"
[[ "$FAIL" -eq 0 ]]
