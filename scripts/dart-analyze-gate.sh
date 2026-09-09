#!/usr/bin/env bash
# dart analyze — yalnızca ERROR seviyesinde çıkış kodu 1.
# WARNING: raporlanır, build engellenmez.
# INFO: yok sayılır (sayıma dahil değil, fail tetiklemez).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE="${MOBILE_DIR:-$ROOT/mobile}"
OUT="${ANALYZE_OUTPUT:-/tmp/canlifal-analyze.txt}"

if ! command -v dart >/dev/null 2>&1; then
  echo "dart SDK bulunamadı"
  exit 1
fi

cd "$MOBILE"
flutter pub get >/dev/null 2>&1 || dart pub get >/dev/null 2>&1 || true

set +e
dart analyze lib 2>&1 | tee "$OUT"
ec=$?
set -e

# Çıktı formatları: "  error - path:line:col - msg" veya "  error • path:line:col • msg"
# Standart grep/awk — CI runner'da ek paket (rg) gerektirmez.
error_count=$(awk '/error -|error •/ && $0 !~ /^Analyzing/ { c++ } END { print c + 0 }' "$OUT")
warning_count=$(awk '/warning -|warning •/ && $0 !~ /^Analyzing/ { c++ } END { print c + 0 }' "$OUT")
info_count=$(awk '/info -|info •/ && $0 !~ /^Analyzing/ { c++ } END { print c + 0 }' "$OUT")

# Özet satırı: "N issues found."
total_line=$(grep -oE '[0-9]+ issues found\.' "$OUT" 2>/dev/null | tail -1 || true)

echo ""
echo "── analyze özeti ──"
echo "  ERROR:   $error_count"
echo "  WARNING: $warning_count (rapor only)"
echo "  INFO:    $info_count (yok sayıldı)"
echo "  dart exit code: $ec"
[[ -n "$total_line" ]] && echo "  $total_line"

if [[ "${error_count:-0}" -gt 0 ]]; then
  echo ""
  echo "❌ Analyze ERROR — APK engellendi ($error_count hata, dart exit=$ec)"
  awk '/error -|error •/ && $0 !~ /^Analyzing/ { print; if (++n >= 20) exit }' "$OUT"
  exit 1
fi

# Exit 3+ = analyzer ERROR; 2 = warning only (Gate 1 geçer).
if [[ "$ec" -ge 3 ]]; then
  echo ""
  echo "❌ dart analyze exit code $ec (ERROR — parse: $error_count satır)"
  awk '/error -|error •/ && $0 !~ /^Analyzing/ { print; if (++n >= 20) exit }' "$OUT"
  exit 1
fi

echo ""
echo "✅ Analyze ERROR yok — WARNING/INFO APK'yı engellemez"
exit 0
