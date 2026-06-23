#!/usr/bin/env bash
# Acceptance test yardımcıları — kaynak: scripts/run-acceptance-tests.sh
set -euo pipefail

BASE="${CANLIFAL_BASE_URL:-https://canlifal.com}"
REPORT_DIR="${ACCEPTANCE_REPORT_DIR:-docs}"
REPORT_JSON="${REPORT_DIR}/ACCEPTANCE_TEST_REPORT.json"
REPORT_MD="${REPORT_DIR}/ACCEPTANCE_TEST_REPORT.md"
RUN_ID="${GITHUB_RUN_ID:-local-$(date +%s)}"

PASS=0
FAIL=0
SKIP=0
declare -a RESULT_LINES=()

require_cmd() {
  for c in "$@"; do
    command -v "$c" >/dev/null 2>&1 || {
      echo "Gerekli komut yok: $c" >&2
      exit 2
    }
  done
}

json_field() {
  local expr="$1"
  python3 -c "import json,sys; d=json.load(sys.stdin); print(d$expr)" 2>/dev/null || true
}

http_code() {
  curl -sS -o /dev/null -w "%{http_code}" "$@"
}

curl_json() {
  curl -sS "$@"
}

mobile_login() {
  local body="$1"
  curl -sS -X POST "$BASE/api/auth/mobile-login" \
    -H "Content-Type: application/json" \
    -d "$body"
}

extract_token() {
  local resp="$1"
  local tok
  tok=$(printf '%s' "$resp" | json_field "['accessToken']")
  if [[ -z "$tok" ]]; then
    tok=$(printf '%s' "$resp" | json_field "['token']")
  fi
  if [[ -z "$tok" ]]; then
    tok=$(printf '%s' "$resp" | json_field "['data']['accessToken']")
  fi
  if [[ -z "$tok" ]]; then
    tok=$(printf '%s' "$resp" | json_field "['data']['token']")
  fi
  printf '%s' "$tok"
}

record() {
  local id="$1" name="$2" status="$3" detail="${4:-}"
  local icon
  case "$status" in
    PASS) icon="✅"; PASS=$((PASS + 1)) ;;
    FAIL) icon="❌"; FAIL=$((FAIL + 1)) ;;
    SKIP) icon="⏭️"; SKIP=$((SKIP + 1)) ;;
    *) icon="•" ;;
  esac
  RESULT_LINES+=("| $id | $name | $icon $status | ${detail//|/\\|} |")
  echo "$icon [$id] $name — $status${detail:+ ($detail)}"
}

require_secret() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    record "$2" "$3" "FAIL" "Eksik secret/env: $name"
    return 1
  fi
  return 0
}

finalize_reports() {
  mkdir -p "$REPORT_DIR"
  local ts
  ts="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  {
    echo "# Acceptance Test Raporu"
    echo ""
    echo "| Alan | Değer |"
    echo "|------|--------|"
    echo "| Tarih | $ts |"
    echo "| Run | $RUN_ID |"
    echo "| API | $BASE |"
    echo "| Geçti | $PASS |"
    echo "| Başarısız | $FAIL |"
    echo "| Atlandı | $SKIP |"
    echo ""
    echo "## Sonuçlar"
    echo ""
    echo "| # | Test | Durum | Detay |"
    echo "|---|------|-------|-------|"
    for line in "${RESULT_LINES[@]}"; do
      echo "$line"
    done
    echo ""
    if [[ "$FAIL" -gt 0 ]]; then
      echo "**Release APK oluşturulmadı** — yukarıdaki başarısız testleri düzeltin."
    else
      echo "**API acceptance testleri geçti** — istemci testleri bekleniyor."
    fi
  } >"$REPORT_MD"

  python3 - "$REPORT_JSON" "$PASS" "$FAIL" "$SKIP" <<'PY'
import json, sys
path, p, f, s = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4])
rows = []
for line in open(sys.environ.get("REPORT_MD", ""), encoding="utf-8") if False else []:
    pass
# parse from env RESULT_LINES_RAW if set
raw = __import__("os").environ.get("RESULT_LINES_RAW", "")
for line in raw.splitlines():
    line = line.strip()
    if not line.startswith("|"):
        continue
    parts = [x.strip() for x in line.strip("|").split("|")]
    if len(parts) < 4 or parts[0] == "#":
        continue
    rows.append({"id": parts[0], "name": parts[1], "status": parts[2], "detail": parts[3]})
data = {
    "runId": __import__("os").environ.get("RUN_ID", ""),
    "baseUrl": __import__("os").environ.get("BASE", ""),
    "pass": p,
    "fail": f,
    "skip": s,
    "results": rows,
}
with open(path, "w", encoding="utf-8") as out:
    json.dump(data, out, ensure_ascii=False, indent=2)
PY

  echo ""
  echo "=== Acceptance özeti: $PASS geçti, $FAIL başarısız, $SKIP atlandı ==="
  echo "Rapor: $REPORT_MD"
  if [[ "$FAIL" -gt 0 ]]; then
    return 1
  fi
  return 0
}
