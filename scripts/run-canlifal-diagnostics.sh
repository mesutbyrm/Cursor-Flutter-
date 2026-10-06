#!/usr/bin/env bash
# Gerçek Android cihaz diagnostic — mock PASS yok.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
REPORT="$ROOT/CANLIFAL_DIAGNOSTIC_REPORT.md"
BUGS="$ROOT/CANLIFAL_BUGS_FOUND.md"
REAL_DEVICE="$ROOT/CANLIFAL_REAL_DEVICE_TEST.md"
FIXES="$ROOT/CANLIFAL_FIXES_APPLIED.md"

FLUTTER="${FLUTTER:-flutter}"
if ! command -v "$FLUTTER" >/dev/null 2>&1; then
  if [[ -x /opt/flutter/bin/flutter ]]; then
    FLUTTER=/opt/flutter/bin/flutter
  else
    echo "TEST NOT RUN — Flutter SDK bulunamadı" | tee "$REPORT"
    exit 2
  fi
fi

cd "$MOBILE"
DEVICE_ID="$("$FLUTTER" devices 2>/dev/null | awk '/• android/{print $1; exit}')"
TS="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"

if [[ -z "${DEVICE_ID:-}" ]]; then
  cat >"$REPORT" <<EOF
# CANLIFAL Diagnostic Report

## OVERALL STATUS: **NOT RUN**

Device: **TEST NOT RUN** — Android cihaz bağlı değil (\`flutter devices\`).

Updated: $TS

Mock/unit testler bu rapora PASS olarak yazılmaz.
EOF
  echo "TEST NOT RUN — Android cihaz yok" | tee "$REAL_DEVICE"
  exit 2
fi

export CANLIFAL_REAL_DEVICE_TEST=true
DART_DEFINES="--dart-define=CANLIFAL_REAL_DEVICE_TEST=true --dart-define=CANLIFAL_DIAGNOSTICS=true"

echo "Device: $DEVICE_ID"
"$FLUTTER" pub get

ANALYZE=PASS
if ! "$FLUTTER" analyze >/tmp/cf-diag-analyze.log 2>&1; then
  ANALYZE=FAIL
fi

UNIT=PASS
if ! "$FLUTTER" test test/core/diagnostics/ >/tmp/cf-diag-unit.log 2>&1; then
  UNIT=FAIL
fi

INTEG=NOT_RUN
INTEG_LOG=/tmp/cf-diag-integration.log
if "$FLUTTER" test integration_test/ -d "$DEVICE_ID" $DART_DEFINES >"$INTEG_LOG" 2>&1; then
  INTEG=PASS
else
  INTEG=FAIL
fi

grep -A999 '===CANLIFAL_DIAG_JSON_START===' "$INTEG_LOG" 2>/dev/null | tail -n +2 | grep -B999 '===CANLIFAL_DIAG_JSON_END===' | head -n -1 >"$REPORT.tmp" || true
if [[ -s "$REPORT.tmp" ]]; then
  mv "$REPORT.tmp" "$REPORT"
else
  cat >"$REPORT" <<EOF
# CANLIFAL Diagnostic Report

## OVERALL STATUS: **NOT RUN** (integration output missing)

Device: $DEVICE_ID
Updated: $TS

See log: integration_test run in CI/local.
EOF
fi

cat >"$REAL_DEVICE" <<EOF
# CANLIFAL Real Device Test

Updated: $TS
Device: $DEVICE_ID
Integration: **$INTEG**
flutter analyze: **$ANALYZE**
flutter test (diagnostics unit): **$UNIT**

Log: \`$INTEG_LOG\`
EOF

if [[ ! -f "$FIXES" ]]; then
  cat >"$FIXES" <<EOF
# CANLIFAL Fixes Applied (diagnostic loop)

Otomatik düzeltme döngüsü: RUN → FAIL → ROOT CAUSE → FIX → RUN AGAIN.

Henüz bu oturumda otomatik fix uygulanmadı — yalnızca altyapı eklendi.
EOF
fi

if [[ ! -f "$BUGS" ]]; then
  echo "# CANLIFAL Bugs Found" >"$BUGS"
  echo "" >>"$BUGS"
  echo "(Bkz. integration çıktısı ve CANLIFAL_DIAGNOSTIC_REPORT.md)" >>"$BUGS"
fi

echo "Reports: $REPORT , $REAL_DEVICE"
exit 0
