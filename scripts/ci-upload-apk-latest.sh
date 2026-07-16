#!/usr/bin/env bash
# apk-latest rolling release — asset yükle (make_latest kullanmaz; GITHUB_TOKEN uyumlu).
set -euo pipefail

APK_PATH="${1:-canlifal-mobile-release.apk}"
TITLE="${2:-Canlifal APK}"
NOTES_PATH="${3:-/tmp/release_notes_min.md}"
TARGET_SHA="${4:-${GITHUB_SHA:-}}"

if [[ ! -s "$APK_PATH" ]]; then
  echo "APK bulunamadı: $APK_PATH" >&2
  exit 1
fi

if [[ -z "${GH_TOKEN:-${GITHUB_TOKEN:-}}" ]]; then
  echo "GH_TOKEN veya GITHUB_TOKEN gerekli" >&2
  exit 1
fi

export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"

if gh release view apk-latest >/dev/null 2>&1; then
  echo "Mevcut apk-latest release güncelleniyor…"
  gh release upload apk-latest "$APK_PATH" --clobber
  gh release edit apk-latest --title "$TITLE" --notes-file "$NOTES_PATH"
else
  echo "Yeni apk-latest release oluşturuluyor…"
  args=(gh release create apk-latest "$APK_PATH" --title "$TITLE" --notes-file "$NOTES_PATH")
  if [[ -n "$TARGET_SHA" ]]; then
    args+=(--target "$TARGET_SHA")
  fi
  "${args[@]}"
fi

echo "apk-latest yüklendi: $TITLE"
