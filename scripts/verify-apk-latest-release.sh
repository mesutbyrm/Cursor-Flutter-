#!/usr/bin/env bash
# apk-latest indirme + metadata doğrulama (GitHub API birincil, CDN ikincil).
set -euo pipefail

EXPECT_NAME="${1:?version_name}"
EXPECT_BUILD="${2:?version_code}"
LOCAL_APK="${3:-canlifal-mobile-release.apk}"
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
RUN_ID="${GITHUB_RUN_ID:-$(date +%s)}"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

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

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

LOCAL_SHA=$(sha256_file "$LOCAL_APK")
echo "Local APK SHA256: $LOCAL_SHA"
verify_apk "$LOCAL_APK"

download_release_asset() {
  local dest="$1"
  local auth=()
  if [[ -n "$TOKEN" ]]; then
    auth=(-H "Authorization: Bearer ${TOKEN}")
  fi
  local asset_id
  asset_id=$(curl -sS "${auth[@]}" \
    "https://api.github.com/repos/${REPO}/releases/tags/apk-latest" \
    | python3 -c "import json,sys; d=json.load(sys.stdin); print(next((a['id'] for a in d.get('assets',[]) if a.get('name')=='canlifal-mobile-release.apk'), ''))" 2>/dev/null || true)
  if [[ -z "$asset_id" ]]; then
    return 1
  fi
  echo "GitHub release asset id=${asset_id}"
  curl -sS -L "${auth[@]}" \
    -H "Accept: application/octet-stream" \
    -o "$dest" \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}"
}

try_remote_apk() {
  local dest="$1" source="$2"
  if [[ ! -s "$dest" ]]; then
    return 1
  fi
  local remote_sha
  remote_sha=$(sha256_file "$dest")
  if [[ "$remote_sha" != "$LOCAL_SHA" ]]; then
    echo "${source} SHA eşleşmedi: remote=${remote_sha}"
    return 1
  fi
  verify_apk "$dest"
  write_out "http_code=200"
  write_out "metadata=PASS"
  write_out "verify_source=${source}"
  return 0
}

echo "GitHub API asset doğrulama (birincil)..."
sleep 10
if download_release_asset /tmp/canlifal-apk-api.apk && try_remote_apk /tmp/canlifal-apk-api.apk github_api; then
  exit 0
fi

CDN_URL="https://github.com/${REPO}/releases/download/apk-latest/canlifal-mobile-release.apk"
HTTP="000"
echo "CDN doğrulama (ikincil)..."
for attempt in $(seq 1 12); do
  HTTP=$(curl -sS -L \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o /tmp/canlifal-apk-verify.apk \
    -w '%{http_code}' \
    "${CDN_URL}?v=${RUN_ID}-${attempt}" || echo "000")
  echo "CDN attempt ${attempt} HTTP=${HTTP}"
  if [[ "$HTTP" == "200" ]] && try_remote_apk /tmp/canlifal-apk-verify.apk cdn; then
    write_out "http_code=${HTTP}"
    exit 0
  fi
  sleep 20
done

write_out "http_code=${HTTP}"
write_out "metadata=FAIL"
exit 1
