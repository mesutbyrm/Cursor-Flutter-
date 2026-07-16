#!/usr/bin/env bash
# apk-latest rolling release — GitHub Upload API (softprops make_latest 403/HTML sorununu atlar).
set -euo pipefail

APK_PATH="${1:-canlifal-mobile-release.apk}"
TITLE="${2:-Canlifal APK}"
NOTES_PATH="${3:-/tmp/release_notes_min.md}"
ASSET_NAME="${4:-canlifal-mobile-release.apk}"

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY gerekli}"
TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:?GITHUB_TOKEN gerekli}}"

if [[ ! -s "$APK_PATH" ]]; then
  echo "APK bulunamadı: $APK_PATH" >&2
  exit 1
fi

api() {
  curl -fsSL \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "$@"
}

upload_asset() {
  local release_id="$1"
  api -X POST \
    -H "Content-Type: application/vnd.android.package-archive" \
    --data-binary @"${APK_PATH}" \
    "https://uploads.github.com/repos/${REPO}/releases/${release_id}/assets?name=${ASSET_NAME}"
}

patch_release() {
  local release_id="$1"
  local payload
  payload=$(jq -n --arg name "$TITLE" --rawfile body "$NOTES_PATH" '{name: $name, body: $body}')
  api -X PATCH \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://api.github.com/repos/${REPO}/releases/${release_id}"
}

if release_json="$(api "https://api.github.com/repos/${REPO}/releases/tags/apk-latest" 2>/dev/null)"; then
  release_id="$(echo "$release_json" | jq -r '.id')"
  echo "Mevcut apk-latest release id=${release_id}"
  while IFS= read -r asset_id; do
    [[ -z "$asset_id" || "$asset_id" == "null" ]] && continue
    echo "Eski asset siliniyor: ${asset_id}"
    api -X DELETE "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}" >/dev/null
  done < <(echo "$release_json" | jq -r --arg n "$ASSET_NAME" '.assets[]? | select(.name==$n) | .id')
  upload_asset "$release_id" >/dev/null
  patch_release "$release_id" >/dev/null
else
  echo "Yeni apk-latest release oluşturuluyor…"
  payload=$(jq -n \
    --arg tag "apk-latest" \
    --arg name "$TITLE" \
    --rawfile body "$NOTES_PATH" \
  '{tag_name: $tag, name: $name, body: $body}')
  release_json="$(api -X POST \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "https://api.github.com/repos/${REPO}/releases")"
  release_id="$(echo "$release_json" | jq -r '.id')"
  upload_asset "$release_id" >/dev/null
fi

echo "apk-latest yüklendi: ${TITLE}"
