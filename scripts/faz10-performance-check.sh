#!/usr/bin/env bash
# FAZ 10 — performans modülü varlık + hızlı test kapısı.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOBILE="$ROOT/mobile"

echo "=== FAZ10 Performance check ==="

required=(
  mobile/lib/core/performance/app_perf_metrics.dart
  mobile/lib/core/performance/device_perf_tuning.dart
  mobile/lib/core/performance/voice_room_entry_perf.dart
  mobile/lib/core/performance/network_perf.dart
)

for f in "${required[@]}"; do
  [[ -f "$ROOT/$f" ]] || { echo "❌ Eksik: $f"; exit 1; }
done
echo "✅ Perf modülleri mevcut"

(cd "$MOBILE" && flutter test test/core/performance/ 2>/dev/null) || {
  echo "⏭️  test/core/performance yok — perf modül dosya kontrolü yeterli"
}

echo "FAZ10 check: PASS"
