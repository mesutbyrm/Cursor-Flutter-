#!/usr/bin/env bash
# Canlifal release acceptance testleri — APK derlemeden önce zorunlu.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_DIR="${ACCEPTANCE_REPORT_DIR:-$ROOT/docs}"
export ACCEPTANCE_REPORT_DIR="$REPORT_DIR"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Canlifal Release Acceptance Tests (20 madde)            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

API_FAIL=0
CLIENT_FAIL=0

echo "── API testleri (1–17, 20) ──"
if bash "$ROOT/scripts/acceptance-tests/api-acceptance.sh"; then
  echo "API acceptance: OK"
else
  API_FAIL=1
  echo "API acceptance: BAŞARISIZ"
fi

echo ""
echo "── İstemci testleri (18–20) ──"
if command -v flutter >/dev/null 2>&1; then
  (
    cd "$ROOT/mobile"
    flutter pub get >/dev/null
    flutter test test/acceptance/client_acceptance_test.dart --reporter expanded
  ) && echo "Client acceptance: OK" || CLIENT_FAIL=1
else
  echo "Flutter SDK yok — dart test ile deneniyor..."
  if command -v dart >/dev/null 2>&1; then
  (
    cd "$ROOT/mobile"
    dart pub get >/dev/null
    dart test test/acceptance/client_acceptance_test.dart
  ) && echo "Client acceptance: OK" || CLIENT_FAIL=1
  else
    echo "HATA: flutter/dart bulunamadı"
    CLIENT_FAIL=1
  fi
fi

# İstemci sonuçlarını rapora ekle
if [[ "$CLIENT_FAIL" -eq 0 ]]; then
  {
    echo ""
    echo "| 18 | Müzik sistemi (!istek) | ✅ PASS | flutter test |"
    echo "| 19 | Tema değiştirme | ✅ PASS | flutter test |"
    echo "| 20b | İstemci performans | ✅ PASS | flutter test |"
  } >>"$REPORT_DIR/ACCEPTANCE_TEST_REPORT.md"
else
  {
    echo ""
    echo "| 18–20 | İstemci acceptance | ❌ FAIL | flutter test başarısız |"
  } >>"$REPORT_DIR/ACCEPTANCE_TEST_REPORT.md"
fi

echo ""
if [[ "$API_FAIL" -eq 0 && "$CLIENT_FAIL" -eq 0 ]]; then
  echo "✅ Tüm acceptance testleri geçti — release APK oluşturulabilir."
  exit 0
fi

echo "❌ Acceptance testleri başarısız — release APK oluşturulmayacak."
echo "Rapor: $REPORT_DIR/ACCEPTANCE_TEST_REPORT.md"
exit 1
