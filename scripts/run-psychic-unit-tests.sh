#!/usr/bin/env bash
# Psychic / live_psychics Flutter unit testleri (cihaz gerekmez).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MOBILE="$ROOT/mobile"
TEST_DIR="test/features/live_psychics"

if ! command -v flutter >/dev/null 2>&1; then
  echo "⏭️  Flutter SDK yok — atlandı"
  echo "   Cloud/local: PATH'e flutter ekleyin veya CI'da çalışır"
  exit 0
fi

echo "=== Psychic unit testleri ==="
cd "$MOBILE"
flutter pub get >/dev/null 2>&1 || flutter pub get

if [[ -d "$TEST_DIR" ]]; then
  flutter test "$TEST_DIR" --reporter compact
else
  echo "❌ $TEST_DIR bulunamadı"
  exit 1
fi
