#!/usr/bin/env bash
# Repodaki Flutter sürümü + sabit GitHub apk-latest indirme URL'si.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PUBSPEC="${ROOT}/mobile/pubspec.yaml"
VERSION="?"
if [[ -f "$PUBSPEC" ]]; then
  VERSION="$(grep -E '^version:' "$PUBSPEC" | head -1 | sed 's/version:[[:space:]]*//')"
fi
URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
echo "Canlifal APK (Flutter ${VERSION})"
echo "${URL}"
