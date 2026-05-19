#!/usr/bin/env bash
# Flutter release APK’yı downloads/canlifal-mobile-release.apk olarak kopyalar.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="${1:-$ROOT/mobile/build/app/outputs/flutter-apk/app-release.apk}"
DST="$ROOT/downloads/canlifal-mobile-release.apk"
if [[ ! -f "$SRC" ]]; then
  echo "Kaynak bulunamadı: $SRC" >&2
  echo "Önce: cd mobile && flutter build apk --release" >&2
  exit 1
fi
mkdir -p "$ROOT/downloads"
cp -f "$SRC" "$DST"
echo "Kopyalandı: $DST"
