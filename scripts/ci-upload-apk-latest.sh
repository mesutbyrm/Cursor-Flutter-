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
REPO="${GITHUB_REPOSITORY:-}"

gh_args=()
if [[ -n "$REPO" ]]; then
  gh_args=(--repo "$REPO")
fi

# Önce mevcut release'e yükle (view bazen 403 döner; upload çalışır).
if gh release upload apk-latest "$APK_PATH" --clobber "${gh_args[@]}" 2>/dev/null; then
  echo "apk-latest asset güncellendi"
  gh release edit apk-latest --title "$TITLE" --notes-file "$NOTES_PATH" "${gh_args[@]}"
  echo "apk-latest yüklendi: $TITLE"
  exit 0
fi

echo "Yeni apk-latest release oluşturuluyor…"
create_args=(
  gh release create apk-latest "$APK_PATH"
  --title "$TITLE"
  --notes-file "$NOTES_PATH"
)
if [[ -n "$TARGET_SHA" ]]; then
  create_args+=(--target "$TARGET_SHA")
fi
if [[ -n "$REPO" ]]; then
  create_args+=(--repo "$REPO")
fi
"${create_args[@]}"
echo "apk-latest oluşturuldu: $TITLE"
