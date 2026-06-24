#!/usr/bin/env bash
# Release gate — APK/AAB öncesi 9 zorunlu madde.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${ACCEPTANCE_REPORT_DIR:-$ROOT/docs}"
export ACCEPTANCE_REPORT_DIR="$REPORT_DIR"
REPORT_MD="$REPORT_DIR/RELEASE_GATE_REPORT.md"
REPORT_JSON="$REPORT_DIR/RELEASE_GATE_REPORT.json"

mkdir -p "$REPORT_DIR"

PASS=0
FAIL=0
declare -a GATE_LINES=()

gate_record() {
  local id="$1" name="$2" status="$3" detail="${4:-}"
  local icon
  case "$status" in
    PASS) icon="✅"; PASS=$((PASS + 1)) ;;
    FAIL) icon="❌"; FAIL=$((FAIL + 1)) ;;
    SKIP) icon="⏭️" ;;
    *) icon="•" ;;
  esac
  GATE_LINES+=("| $id | $name | $icon $status | ${detail//|/\\|} |")
  echo "$icon [Gate $id] $name — $status${detail:+ ($detail)}"
}

write_final_report() {
  local ts
  ts="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  {
    echo "# Release Gate Raporu"
    echo ""
    echo "| Alan | Değer |"
    echo "|------|--------|"
    echo "| Tarih | $ts |"
    echo "| Run | ${GITHUB_RUN_ID:-local} |"
    echo "| Geçti | $PASS |"
    echo "| Başarısız | $FAIL |"
    echo ""
    echo "## Sonuçlar"
    echo ""
    echo "| # | Kontrol | Durum | Detay |"
    echo "|---|---------|-------|-------|"
    for line in "${GATE_LINES[@]}"; do
      echo "$line"
    done
    if [[ -f "$REPORT_DIR/ACCEPTANCE_TEST_REPORT.md" ]]; then
      echo ""
      echo "## API detay (madde 3–8)"
      cat "$REPORT_DIR/ACCEPTANCE_TEST_REPORT.md"
    fi
    echo ""
    if [[ "$FAIL" -gt 0 ]]; then
      echo "**Release APK/AAB oluşturulmadı.**"
    elif grep -q 'SKIP' <<<"${GATE_LINES[*]:-}"; then
      echo "**Release gate geçti** (bazı API kontrolleri secret eksikliği nedeniyle atlandı) — build adımına devam."
    else
      echo "**Release gate geçti — build adımına devam.**"
    fi
  } >"$REPORT_MD"

  export GATE_LINES_RAW PASS_COUNT="$PASS" FAIL_COUNT="$FAIL"
  python3 - "$REPORT_JSON" <<'PY'
import json, os, sys
rows = []
for line in os.environ.get("GATE_LINES_RAW", "").splitlines():
    line = line.strip()
    if not line.startswith("|"):
        continue
    parts = [p.strip() for p in line.strip("|").split("|")]
    if len(parts) < 4:
        continue
    rows.append({"gate": parts[0], "name": parts[1], "status": parts[2], "detail": parts[3]})
with open(sys.argv[1], "w", encoding="utf-8") as f:
    json.dump({
        "pass": int(os.environ.get("PASS_COUNT", 0)),
        "fail": int(os.environ.get("FAIL_COUNT", 0)),
        "gates": rows,
    }, f, ensure_ascii=False, indent=2)
PY
}

merge_api_gate_results() {
  local api_report="$REPORT_DIR/ACCEPTANCE_TEST_REPORT.md"
  if [[ ! -f "$api_report" ]]; then
    for id in 3 4 5 6 7 8; do
      gate_record "$id" "API gate $id" FAIL "rapor yok"
    done
    return
  fi
  while IFS= read -r line; do
    [[ "$line" != \|* ]] && continue
    local parts
    IFS='|' read -ra parts <<<"${line//|/ | }"
    local num name status detail
    num=$(echo "${parts[1]:-}" | tr -d ' ')
    name=$(echo "${parts[2]:-}" | xargs)
    status=$(echo "${parts[3]:-}" | xargs)
    detail=$(echo "${parts[4]:-}" | xargs)
    [[ -z "$num" || "$num" == "#" ]] && continue
    [[ ! "$num" =~ ^[0-9]+$ ]] && continue
    if echo "$status" | grep -q 'PASS'; then
      gate_record "$num" "$name" PASS "$detail"
    elif echo "$status" | grep -q 'SKIP'; then
      gate_record "$num" "$name" SKIP "$detail"
    else
      gate_record "$num" "$name" FAIL "$detail"
    fi
  done < <(grep '^| [0-9]' "$api_report" || true)
}

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Canlifal Release Gate (9 madde)                         ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Gate 1 — flutter analyze (yalnızca ERROR engeller)
echo "── Gate 1: flutter analyze ──"
ANALYZE_OK=0
if command -v flutter >/dev/null 2>&1; then
  if bash "$ROOT/scripts/dart-analyze-gate.sh"; then
    gate_record 1 "flutter analyze sıfır hata" PASS "ERROR yok"
    ANALYZE_OK=1
  else
    gate_record 1 "flutter analyze sıfır hata" FAIL "ERROR var — /tmp/canlifal-analyze.txt"
  fi
else
  gate_record 1 "flutter analyze sıfır hata" FAIL "flutter SDK yok"
fi

# Gate 2 — flutter test
echo ""
echo "── Gate 2: flutter test ──"
TEST_OK=0
if [[ "$ANALYZE_OK" -eq 1 ]]; then
  if (cd "$ROOT/mobile" && flutter test --reporter compact); then
    gate_record 2 "flutter test tamamı" PASS "tüm testler geçti"
    TEST_OK=1
  else
    gate_record 2 "flutter test tamamı" FAIL "başarısız test var"
  fi
else
  gate_record 2 "flutter test tamamı" FAIL "Gate 1 başarısız"
fi

# Gate 3–8 — API
echo ""
echo "── Gate 3–8: API doğrulama ──"
if [[ "$TEST_OK" -eq 1 ]]; then
  chmod +x "$ROOT/scripts/acceptance-tests/"*.sh
  rm -f "$REPORT_DIR/ACCEPTANCE_TEST_REPORT.md" "$REPORT_DIR/ACCEPTANCE_TEST_REPORT.json"
  if bash "$ROOT/scripts/acceptance-tests/api-release-gate.sh"; then
    merge_api_gate_results
  else
    merge_api_gate_results
  fi
else
  for id in 3 4 5 6 7 8; do
    gate_record "$id" "API gate" FAIL "Gate 2 başarısız — atlandı"
  done
fi

write_final_report

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "❌ Release gate başarısız — APK/AAB oluşturulmayacak."
  echo "Rapor: $REPORT_MD"
  exit 1
fi

echo ""
echo "✅ Release gate (1–8) geçti — Gate 9 release build workflow'da."
exit 0
