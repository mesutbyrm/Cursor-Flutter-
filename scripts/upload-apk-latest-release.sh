#!/usr/bin/env bash
# apk-latest release — gh CLI ile diskten yükleme (büyük APK; octokit readFileSync kullanma).
set -euo pipefail

TAG="${APK_LATEST_TAG:-apk-latest}"
TITLE="${RELEASE_TITLE:?RELEASE_TITLE gerekli}"
NOTES_PATH="${NOTES_PATH:?NOTES_PATH gerekli}"
TARGET_SHA="${BUILD_SHA:-${GITHUB_SHA:?GITHUB_SHA gerekli}}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY gerekli}"

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "::error::GH_TOKEN yok"
  exit 1
fi

export GH_TOKEN

if [[ ! -f "$NOTES_PATH" ]]; then
  echo "::error::Release notları bulunamadı: $NOTES_PATH"
  exit 1
fi

ensure_release() {
  if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    gh release edit "$TAG" \
      --repo "$REPO" \
      --title "$TITLE" \
      --notes-file "$NOTES_PATH" \
      --target "$TARGET_SHA"
    echo "Mevcut release güncellendi: $TAG"
    return 0
  fi
  gh release create "$TAG" \
    --repo "$REPO" \
    --title "$TITLE" \
    --notes-file "$NOTES_PATH" \
    --target "$TARGET_SHA" \
    --latest=false
  echo "Yeni release oluşturuldu: $TAG"
}

upload_with_retry() {
  local file="$1"
  local attempt=1
  local max="${APK_UPLOAD_RETRIES:-5}"
  local delay="${APK_UPLOAD_RETRY_BASE_SEC:-20}"

  while (( attempt <= max )); do
    echo "Yükleme denemesi ${attempt}/${max}: ${file} ($(stat -c%s "$file") bytes)"
    if gh release upload "$TAG" "$file" --clobber --repo "$REPO"; then
      echo "Asset yüklendi: ${file}"
      return 0
    fi
    echo "::warning::gh release upload başarısız (${file}), ${delay}s sonra tekrar"
    sleep "$delay"
    delay=$((delay + 15))
    attempt=$((attempt + 1))
  done

  echo "::error::Asset yüklenemedi: ${file}"
  return 1
}

ensure_release

for asset in canlifal-mobile-release.apk canlifal-mobile-arm64-release.apk; do
  if [[ -f "$asset" && -s "$asset" ]]; then
    upload_with_retry "$asset"
  else
    echo "::warning::APK atlandı (yok veya boş): $asset"
  fi
done

gh release edit "$TAG" \
  --repo "$REPO" \
  --title "$TITLE" \
  --notes-file "$NOTES_PATH" \
  --target "$TARGET_SHA"

echo "apk-latest tamam: ${TITLE}"
