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

# Çıktı formatı: "  error - path:line:col - message"
# grep kullan (CI runner'da rg yok — rg eksikliği ERROR sayımını 0 yapıp yanlış PASS üretiyordu).
error_count=$(grep -cE '^\s*error\s+-' "$OUT" 2>/dev/null || true)
warning_count=$(grep -cE '^\s*warning\s+-' "$OUT" 2>/dev/null || true)
info_count=$(grep -cE '^\s*info\s+-' "$OUT" 2>/dev/null || true)
error_count=${error_count:-0}
warning_count=${warning_count:-0}
info_count=${info_count:-0}

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
  echo "❌ Analyze ERROR — APK engellendi ($error_count hata)"
  grep -E '^\s*error\s+-' "$OUT" | head -20 || true
  exit 1
fi

echo ""
echo "✅ Analyze ERROR yok — WARNING/INFO APK'yı engellemez"
exit 0
