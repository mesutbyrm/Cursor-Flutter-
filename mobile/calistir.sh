#!/usr/bin/env bash
# Canlifal mobil — tek komutla çalıştır (Android telefon veya emülatör gerekir)
set -euo pipefail
cd "$(dirname "$0")"

echo "=== Canlifal Flutter ==="
echo "API: https://canlifal.com"
echo ""

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter yüklü değil. Önce kurun: https://docs.flutter.dev/get-started/install"
  exit 1
fi

flutter pub get
echo ""
echo "Bağlı cihazlar:"
flutter devices
echo ""
echo "Uygulama başlatılıyor (ilk seferde derleme birkaç dakika sürebilir)..."
exec flutter run --dart-define=API_BASE_URL=https://canlifal.com "$@"
