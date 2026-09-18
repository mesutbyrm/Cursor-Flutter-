#!/usr/bin/env bash
# apk-latest indirme + metadata doğrulama (GitHub API birincil, CDN ikincil).
set -euo pipefail

EXPECT_NAME="${1:?version_name}"
EXPECT_BUILD="${2:?version_code}"
LOCAL_APK="${3:-canlifal-mobile-release.apk}"
EXPECT_PACKAGE="${EXPECT_PACKAGE:-com.mesutbyrm.canlifal}"
REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
RUN_ID="${GITHUB_RUN_ID:-$(date +%s)}"
OUT="${GITHUB_OUTPUT:-/dev/stdout}"
TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

AAPT=$(find "${ANDROID_HOME:-/usr/local/lib/android/sdk}/build-tools" -name aapt -type f 2>/dev/null | sort -V | tail -1)
if [[ -z "$AAPT" ]]; then
  echo "::error::aapt bulunamadı (ANDROID_HOME/build-tools)"
  exit 1
fi

write_out() {
  printf '%s\n' "$@" >> "$OUT"
}

fail_metadata() {
  local reason="$1"
  local http="${2:-000}"
  echo "::error::APK metadata doğrulama FAIL: ${reason}"
  write_out "http_code=${http}"
  write_out "metadata=FAIL"
  write_out "metadata_reason=${reason}"
  exit 1
}

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

read_apk_fields() {
  local apk="$1"
  local BADGING
  BADGING=$("$AAPT" dump badging "$apk" 2>/dev/null) || {
    echo "aapt dump badging başarısız: ${apk}" >&2
    return 1
  }
  PACKAGE=$(echo "$BADGING" | sed -n "s/^package: name='\([^']*\)'.*/\1/p" | head -1)
  VERSION_NAME=$(echo "$BADGING" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p" | head -1)
  VERSION_CODE=$(echo "$BADGING" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p" | head -1)
}

assert_apk_metadata() {
  local apk="$1"
  local label="${2:-APK}"
  local http_on_fail="${3:-000}"

  if [[ ! -f "$apk" || ! -s "$apk" ]]; then
    fail_metadata "${label} dosyası yok veya boş: ${apk}" "$http_on_fail"
  fi

  local PACKAGE VERSION_NAME VERSION_CODE
  read_apk_fields "$apk" || fail_metadata "${label}: aapt badging okunamadı" "$http_on_fail"

  local mismatches=()
  if [[ "$PACKAGE" != "$EXPECT_PACKAGE" ]]; then
    mismatches+=("packageName expected='${EXPECT_PACKAGE}' actual='${PACKAGE}'")
  fi
  if [[ "$VERSION_NAME" != "$EXPECT_NAME" ]]; then
    mismatches+=("versionName expected='${EXPECT_NAME}' actual='${VERSION_NAME}'")
  fi
  if [[ "$VERSION_CODE" != "$EXPECT_BUILD" ]]; then
    mismatches+=("versionCode expected='${EXPECT_BUILD}' actual='${VERSION_CODE}'")
  fi

  if ((${#mismatches[@]} > 0)); then
    echo "${label} metadata mismatch:"
    printf '  - %s\n' "${mismatches[@]}"
    fail_metadata "${label}: $(IFS='; '; echo "${mismatches[*]}")" "$http_on_fail"
  fi

  echo "${label} metadata OK: package='${PACKAGE}' versionName='${VERSION_NAME}' versionCode='${VERSION_CODE}'"
}

if [[ ! -f "$LOCAL_APK" || ! -s "$LOCAL_APK" ]]; then
  fail_metadata "Yerel build APK bulunamadı: ${LOCAL_APK}" "000"
fi

LOCAL_SHA=$(sha256_file "$LOCAL_APK")
echo "Local APK SHA256: ${LOCAL_SHA}"
assert_apk_metadata "$LOCAL_APK" "Local build"

download_release_asset() {
  local dest="$1"
  local dir
  dir=$(dirname "$dest")
  mkdir -p "$dir"
  rm -f "$dest"
  if [[ -n "${GH_TOKEN:-${TOKEN:-}}" ]] && command -v gh >/dev/null 2>&1; then
    export GH_TOKEN="${GH_TOKEN:-${TOKEN}}"
    if gh release download apk-latest --repo "$REPO" \
      -p "canlifal-mobile-release.apk" -D "$dir" --clobber 2>/dev/null \
      && [[ -f "$dir/canlifal-mobile-release.apk" ]]; then
      mv -f "$dir/canlifal-mobile-release.apk" "$dest"
      echo "GitHub release download (gh): canlifal-mobile-release.apk"
      return 0
    fi
  fi
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
  local dest="$1"
  local source="$2"
  local http_code="${3:-200}"

  if [[ ! -s "$dest" ]]; then
    echo "${source}: indirilen APK boş"
    return 1
  fi

  local remote_sha
  remote_sha=$(sha256_file "$dest")
  if [[ "$remote_sha" != "$LOCAL_SHA" ]]; then
    echo "${source} SHA256 mismatch:"
    echo "  local=${LOCAL_SHA}"
    echo "  remote=${remote_sha}"
    return 1
  fi

  assert_apk_metadata "$dest" "${source} release" "$http_code"

  write_out "http_code=${http_code}"
  write_out "metadata=PASS"
  write_out "verify_source=${source}"
  write_out "metadata_reason=ok"
  echo "APK metadata doğrulama PASS (${source}, HTTP=${http_code})"
  return 0
}

LAST_HTTP="000"

echo "GitHub API asset doğrulama (birincil)..."
sleep 10
if download_release_asset /tmp/canlifal-apk-api.apk; then
  if try_remote_apk /tmp/canlifal-apk-api.apk github_api 200; then
    exit 0
  fi
  LAST_HTTP="200"
else
  echo "GitHub API asset indirilemedi — CDN denenecek"
fi

CDN_URL="https://github.com/${REPO}/releases/download/apk-latest/canlifal-mobile-release.apk"
echo "CDN doğrulama (ikincil)..."
for attempt in $(seq 1 12); do
  LAST_HTTP=$(curl -sS -L \
    -H 'Cache-Control: no-cache' \
    -H 'Pragma: no-cache' \
    -o /tmp/canlifal-apk-verify.apk \
    -w '%{http_code}' \
    "${CDN_URL}?v=${RUN_ID}-${attempt}" || echo "000")
  echo "CDN attempt ${attempt} HTTP=${LAST_HTTP}"
  if [[ "$LAST_HTTP" == "200" ]] && try_remote_apk /tmp/canlifal-apk-verify.apk cdn "$LAST_HTTP"; then
    exit 0
  fi
  sleep 20
done

if [[ "$LAST_HTTP" == "200" ]]; then
  fail_metadata "HTTP 200 ancak release APK yerel build ile eşleşmiyor (SHA256 ve/veya metadata); apk-latest güncellenmemiş olabilir" "$LAST_HTTP"
fi

fail_metadata "Release APK indirilemedi (son HTTP=${LAST_HTTP})" "$LAST_HTTP"
