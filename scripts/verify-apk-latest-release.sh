#!/usr/bin/env bash
# apk-latest indirme + metadata doğrulama (CDN gecikmesi + GitHub API yedek).
set -euo pipefail

EXPECT_NAME="${1:?version_name}"
EXPECT_BUILD="${2:?version_code}"
LOCAL_APK="${3:-canlifal-mobile-release.apk}"
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
RUN_ID="${GITHUB_RUN_ID:-$(date +%s)}"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"

AAPT=$(find "${ANDROID_HOME:-/usr/local/lib/android/sdk}/build-tools" -name aapt -type f 2>/dev/null | sort -V | tail -1)
if [[ -z "$AAPT" ]]; then
  echo "aapt bulunamadı" >&2
  exit 1
fi

verify_apk() {
  local apk="$1"
  test -s "$apk"
  local BADGING
  BADGING=$("$AAPT" dump badging "$apk")
  echo "$BADGING" | grep -F "versionName='${EXPECT_NAME}'"
  echo "$BADGING" | grep -F "versionCode='${EXPECT_BUILD}'"
}

write_out() {
  printf '%s\n' "$@" >> "$OUT"
}

LOCAL_SHA=$(sha256sum "$LOCAL_APK" | awk '{print $1}')
echo "Local APK SHA256: $LOCAL_SHA"
verify_apk "$LOCAL_APK"

echo "CDN yayılımı için kısa bekleme..."
sleep 45

CDN_URL="https://github.com/${REPO}/releases/download/apk-latest/canlifal-mobile-release.apk"
HTTP="000"
for attempt in $(seq 1 20); do
  HTTP=$(curl -sS -L \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o /tmp/canlifal-apk-verify.apk \
    -w '%{http_code}' \
    "${CDN_URL}?v=${RUN_ID}-${attempt}" || echo "000")
  echo "CDN attempt ${attempt} HTTP=${HTTP}"
  if [[ "$HTTP" == "200" && -s /tmp/canlifal-apk-verify.apk ]]; then
    REMOTE_SHA=$(sha256sum /tmp/canlifal-apk-verify.apk | awk '{print $1}')
    if [[ "$REMOTE_SHA" == "$LOCAL_SHA" ]]; then
      verify_apk /tmp/canlifal-apk-verify.apk
      write_out "http_code=${HTTP}"
      write_out "metadata=PASS"
      write_out "verify_source=cdn"
      exit 0
    fi
    echo "CDN SHA henüz güncellenmedi: remote=${REMOTE_SHA}"
  fi
  sleep 30
done

if command -v gh >/dev/null 2>&1; then
  ASSET_ID=$(gh api "repos/${REPO}/releases/tags/apk-latest" \
    --jq '.assets[] | select(.name=="canlifal-mobile-release.apk") | .id' 2>/dev/null || true)
  if [[ -n "$ASSET_ID" ]]; then
    echo "GitHub API asset indirme id=${ASSET_ID}"
    gh api "repos/${REPO}/releases/assets/${ASSET_ID}" \
      -H "Accept: application/octet-stream" > /tmp/canlifal-apk-verify.apk
    REMOTE_SHA=$(sha256sum /tmp/canlifal-apk-verify.apk | awk '{print $1}')
    if [[ "$REMOTE_SHA" == "$LOCAL_SHA" ]]; then
      verify_apk /tmp/canlifal-apk-verify.apk
      write_out "http_code=200"
      write_out "metadata=PASS"
      write_out "verify_source=github_api"
      exit 0
    fi
    echo "GitHub API SHA eşleşmedi: remote=${REMOTE_SHA}" >&2
  fi
fi

write_out "http_code=${HTTP}"
write_out "metadata=FAIL"
exit 1
