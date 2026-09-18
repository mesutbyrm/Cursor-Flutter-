#!/usr/bin/env bash
# apk-latest release — idempotent asset yükleme (gh + GitHub Upload API).
set -uo pipefail

TAG="${APK_LATEST_TAG:-apk-latest}"
TITLE="${RELEASE_TITLE:?RELEASE_TITLE gerekli}"
NOTES_PATH="${NOTES_PATH:?NOTES_PATH gerekli}"
TARGET_SHA="${BUILD_SHA:-${GITHUB_SHA:?GITHUB_SHA gerekli}}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY gerekli}"
APK_ROOT="${APK_RELEASE_DIR:-${GITHUB_WORKSPACE:-.}}"

REQUIRED_ASSETS=(
  canlifal-mobile-release.apk
  canlifal-mobile-arm64-release.apk
)

if [[ -z "${GH_TOKEN:-}" ]]; then
  echo "::error::GH_TOKEN yok"
  exit 1
fi

export GH_TOKEN

if [[ ! -f "$NOTES_PATH" ]]; then
  echo "::error::Release notları bulunamadı: $NOTES_PATH"
  exit 1
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "::error::gh CLI bulunamadı"
  exit 1
fi

APK_UPLOAD_RETRIES="${APK_UPLOAD_RETRIES:-5}"
APK_UPLOAD_ATTEMPT_TIMEOUT="${APK_UPLOAD_ATTEMPT_TIMEOUT:-8m}"
APK_UPLOAD_RETRY_BASE_SEC="${APK_UPLOAD_RETRY_BASE_SEC:-10}"

# shellcheck disable=SC2034
declare -A UPLOAD_OUTCOME=()
declare -A UPLOAD_LAST_ERROR=()

redact_log() {
  sed -E \
    -e 's/(gh[pousr]_[A-Za-z0-9_]{20,})/***REDACTED***/g' \
    -e 's/(Bearer [A-Za-z0-9._-]+)/Bearer ***REDACTED***/g' \
    -e 's/("token"[[:space:]]*:[[:space:]]*")[^"]+/\1***REDACTED***/g'
}

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

release_json() {
  gh release view "$TAG" --repo "$REPO" --json assets,databaseId 2>/dev/null || return 1
}

release_database_id() {
  release_json | python3 -c "import json,sys; print(json.load(sys.stdin).get('databaseId') or '')" 2>/dev/null || true
}

# GitHub REST DELETE/GET asset uçları sayısal asset id ister (apiUrl son segmenti).
# gh release view --json assets → "id" alanı GraphQL node_id'dir (RA_kw…); REST için kullanılmaz.
release_asset_rest_id() {
  local asset_name="$1"
  release_json | python3 -c "
import json, re, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for a in data.get('assets') or []:
    if a.get('name') != name:
        continue
    api = a.get('apiUrl') or ''
    m = re.search(r'/releases/assets/(\d+)\s*$', api)
    if m:
        print(m.group(1))
        break
    legacy = str(a.get('id') or '')
    if legacy.isdigit():
        print(legacy)
        break
" "$asset_name" 2>/dev/null || true
}

release_asset_node_id() {
  local asset_name="$1"
  release_json | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for a in data.get('assets') or []:
    if a.get('name') == name:
        print(a.get('id') or '')
        break
" "$asset_name" 2>/dev/null || true
}

release_asset_size() {
  local asset_name="$1"
  release_json | python3 -c "
import json, sys
name = sys.argv[1]
try:
    data = json.load(sys.stdin)
except json.JSONDecodeError:
    sys.exit(0)
for a in data.get('assets') or []:
    if a.get('name') == name:
        print(int(a.get('size') or 0))
        break
" "$asset_name" 2>/dev/null || true
}

list_release_asset_names() {
  release_json | python3 -c "
import json, sys
data = json.load(sys.stdin)
for a in data.get('assets') or []:
    n = a.get('name')
    if n:
        print(n)
" 2>/dev/null || true
}

delete_release_asset() {
  local asset_name="$1"
  local asset_id="$2"
  if [[ -z "$asset_id" ]]; then
    asset_id=$(release_asset_rest_id "$asset_name")
  fi
  if [[ -z "$asset_id" ]]; then
    echo "Silinecek asset yok (zaten yok): ${asset_name}"
    return 0
  fi
  local node_id
  node_id=$(release_asset_node_id "$asset_name")
  echo "Mevcut release asset siliniyor: ${asset_name} (rest_asset_id=${asset_id}, node_id=${node_id:-n/a}, tag=${TAG}, repo=${REPO})"
  local body log http
  body=$(mktemp)
  log=$(mktemp)
  set +e
  http=$(curl -sS -X DELETE \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -o "$body" \
    -w '%{http_code}' \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}" 2>"$log")
  local curl_rc=$?
  set -e
  if [[ "$curl_rc" -ne 0 ]]; then
    echo "::error::DELETE curl hatası: ${asset_name} (rest_asset_id=${asset_id}, tag=${TAG}, curl_rc=${curl_rc})"
    redact_log <"$log" | head -20
    redact_log <"$body" | head -40
    rm -f "$body" "$log"
    return 1
  fi
  case "$http" in
    204|200)
      echo "DELETE başarılı HTTP ${http}: ${asset_name} (rest_asset_id=${asset_id})"
      ;;
    404)
      echo "DELETE HTTP 404 — asset zaten yok (idempotent OK): ${asset_name}"
      rm -f "$body" "$log"
      return 0
      ;;
    401)
      echo "::error::DELETE HTTP 401 — kimlik doğrulama hatası. GH_TOKEN/GITHUB_TOKEN geçerli mi? (asset=${asset_name})"
      redact_log <"$body" | head -40
      rm -f "$body" "$log"
      return 1
      ;;
    403)
      echo "::error::DELETE HTTP 403 — release asset silme yetkisi yok. Workflow permissions: contents: write; PAT için repo scope gerekir. (asset=${asset_name}, rest_asset_id=${asset_id})"
      redact_log <"$body" | head -40
      rm -f "$body" "$log"
      return 1
      ;;
    422)
      echo "::error::DELETE HTTP 422 — geçersiz istek (muhtelen yanlış asset id). rest_asset_id=${asset_id} node_id=${node_id:-n/a}"
      redact_log <"$body" | head -40
      rm -f "$body" "$log"
      return 1
      ;;
    *)
      echo "::error::DELETE HTTP ${http}: ${asset_name} (rest_asset_id=${asset_id}, tag=${TAG})"
      redact_log <"$log" | head -20
      redact_log <"$body" | head -40
      rm -f "$body" "$log"
      return 1
      ;;
  esac
  rm -f "$body" "$log"
  local wait=1
  while (( wait <= 12 )); do
    sleep 2
    if [[ -z "$(release_asset_rest_id "$asset_name")" ]]; then
      echo "Asset silindi ve API'de görünmüyor: ${asset_name}"
      return 0
    fi
    wait=$((wait + 1))
  done
  echo "::error::DELETE HTTP ${http} sonrası asset hâlâ listeleniyor: ${asset_name} (tag=${TAG})"
  return 1
}

download_release_asset_via_api() {
  local asset_name="$1"
  local dest="$2"
  local asset_id
  asset_id=$(release_asset_rest_id "$asset_name")
  if [[ -z "$asset_id" ]]; then
    echo "download: asset id bulunamadı (${asset_name})"
    return 1
  fi
  local http log
  log=$(mktemp)
  http=$(curl -sS -L \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/octet-stream" \
    -o "$dest" \
    -w '%{http_code}' \
    "https://api.github.com/repos/${REPO}/releases/assets/${asset_id}" 2>"$log") || http="000"
  if [[ "$http" != "200" ]]; then
    echo "download HTTP ${http} asset=${asset_name} id=${asset_id} tag=${TAG}"
    redact_log <"$log" | head -20
    rm -f "$log" "$dest"
    return 1
  fi
  rm -f "$log"
  if [[ ! -s "$dest" ]]; then
    echo "download boş dosya: ${asset_name}"
    return 1
  fi
  if [[ "$(head -c 2 "$dest" || true)" != "PK" ]]; then
    echo "download APK imzası yok (muhtelen hata gövdesi): ${asset_name}, size=$(stat -c%s "$dest")"
    return 1
  fi
  return 0
}

remote_asset_matches_local_sha() {
  local file="$1"
  local asset_name="$2"
  local tmp
  tmp=$(mktemp)
  if ! download_release_asset_via_api "$asset_name" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  local local_sha remote_sha remote_size local_size
  local_sha=$(sha256_file "$file")
  remote_sha=$(sha256_file "$tmp")
  remote_size=$(stat -c%s "$tmp")
  local_size=$(stat -c%s "$file")
  rm -f "$tmp"
  if [[ "$local_sha" == "$remote_sha" && "$remote_size" == "$local_size" ]]; then
    return 0
  fi
  echo "Release asset doğrulama farklı: ${asset_name} (tag=${TAG})"
  echo "  local  size=${local_size} SHA256=${local_sha}"
  echo "  remote size=${remote_size} SHA256=${remote_sha}"
  return 1
}

upload_asset_github_uploads_api() {
  local file="$1"
  local asset_name="$2"
  local release_id="$3"
  local log resp http size
  size=$(stat -c%s "$file")
  log=$(mktemp)
  resp=$(mktemp)
  set +e
  if command -v timeout >/dev/null 2>&1; then
    http=$(timeout "$APK_UPLOAD_ATTEMPT_TIMEOUT" curl -sS \
      -X POST \
      -H "Authorization: Bearer ${GH_TOKEN}" \
      -H "Content-Type: application/vnd.android.package-archive" \
      -H "Content-Length: ${size}" \
      --data-binary @"${file}" \
      -o "$resp" \
      -w '%{http_code}' \
      "https://uploads.github.com/repos/${REPO}/releases/${release_id}/assets?name=${asset_name}" 2>"$log")
  else
    http=$(curl -sS \
      -X POST \
      -H "Authorization: Bearer ${GH_TOKEN}" \
      -H "Content-Type: application/vnd.android.package-archive" \
      -H "Content-Length: ${size}" \
      --data-binary @"${file}" \
      -o "$resp" \
      -w '%{http_code}' \
      "https://uploads.github.com/repos/${REPO}/releases/${release_id}/assets?name=${asset_name}" 2>"$log")
  fi
  local rc=$?
  set -e
  if [[ "$rc" -eq 124 ]]; then
    echo "Upload API zaman aşımı (${APK_UPLOAD_ATTEMPT_TIMEOUT}): ${asset_name}"
    redact_log <"$log" | head -20
    rm -f "$log" "$resp"
    return 124
  fi
  if [[ "$http" != "201" ]]; then
    echo "Upload API HTTP ${http}: asset=${asset_name} tag=${TAG} release_id=${release_id} local_size=${size}"
    echo "--- Upload API response body (ilk 40 satır) ---"
    redact_log <"$resp" | head -40
    echo "--- Upload API curl stderr ---"
    redact_log <"$log" | head -20
    rm -f "$log" "$resp"
    return 1
  fi
  local api_size api_name
  api_size=$(python3 -c "import json; d=json.load(open('$resp')); print(int(d.get('size') or 0))" 2>/dev/null || echo "0")
  api_name=$(python3 -c "import json; d=json.load(open('$resp')); print(d.get('name') or '')" 2>/dev/null || echo "")
  rm -f "$log" "$resp"
  if [[ "$api_name" != "$asset_name" ]]; then
    echo "Upload API asset adı beklenmiyor: expected=${asset_name} actual=${api_name}"
    return 1
  fi
  if [[ "$api_size" != "$size" ]]; then
    echo "Upload API boyut uyuşmazlığı: expected=${size} api=${api_size} asset=${asset_name}"
    return 1
  fi
  echo "Upload API başarılı (201): ${asset_name} (${api_size} bytes)"
  return 0
}

run_gh_upload() {
  local file="$1"
  local log
  log=$(mktemp)
  set +e
  if command -v timeout >/dev/null 2>&1; then
    timeout "$APK_UPLOAD_ATTEMPT_TIMEOUT" gh release upload "$TAG" "$file" --clobber --repo "$REPO" >"$log" 2>&1
  else
    gh release upload "$TAG" "$file" --clobber --repo "$REPO" >"$log" 2>&1
  fi
  local rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    echo "gh release upload exit=${rc} file=$(basename "$file") tag=${TAG}"
    redact_log <"$log" | head -40
  fi
  rm -f "$log"
  return "$rc"
}

upload_one_asset() {
  local asset_name="$1"
  local file="${APK_ROOT}/${asset_name}"

  if [[ ! -f "$file" || ! -s "$file" ]]; then
    echo "::warning::Yerel APK yok veya boş, atlanıyor: ${asset_name} (path=${file})"
    UPLOAD_OUTCOME["$asset_name"]="skipped_missing_local"
    UPLOAD_LAST_ERROR["$asset_name"]="local file missing: ${file}"
    return 0
  fi

  local local_size remote_size
  local_size=$(stat -c%s "$file")

  if [[ "${APK_FORCE_UPLOAD:-0}" != "1" ]]; then
    remote_size=$(release_asset_size "$asset_name")
    if [[ -n "$remote_size" && "$remote_size" -gt 0 && "$remote_size" == "$local_size" ]]; then
      if remote_asset_matches_local_sha "$file" "$asset_name"; then
        echo "Asset zaten güncel (boyut + SHA256): ${asset_name} (${local_size} bytes)"
        UPLOAD_OUTCOME["$asset_name"]="ok_existing"
        return 0
      fi
      echo "Boyut aynı, içerik farklı — değiştirilecek: ${asset_name}"
    elif [[ -n "$remote_size" && "$remote_size" -gt 0 ]]; then
      echo "Boyut farklı — değiştirilecek: ${asset_name} (remote=${remote_size}, local=${local_size})"
    fi
  fi

  local release_id
  release_id=$(release_database_id)
  if [[ -z "$release_id" ]]; then
    UPLOAD_LAST_ERROR["$asset_name"]="release databaseId missing for tag ${TAG}"
    echo "::error::Release databaseId alınamadı: tag=${TAG} repo=${REPO}"
    UPLOAD_OUTCOME["$asset_name"]="failed"
    return 1
  fi

  local attempt=1 delay="$APK_UPLOAD_RETRY_BASE_SEC" max="$APK_UPLOAD_RETRIES"

  while (( attempt <= max )); do
    echo "Yükleme ${attempt}/${max}: ${asset_name} (${local_size} bytes, tag=${TAG})"

    local existing_id
    existing_id=$(release_asset_rest_id "$asset_name")
    if [[ -n "$existing_id" ]]; then
      if ! delete_release_asset "$asset_name" "$existing_id"; then
        UPLOAD_LAST_ERROR["$asset_name"]="delete failed asset_id=${existing_id}"
        attempt=$((attempt + 1))
        sleep "$delay"
        continue
      fi
    fi

    local upload_rc=1
    if upload_asset_github_uploads_api "$file" "$asset_name" "$release_id"; then
      upload_rc=0
    elif run_gh_upload "$file"; then
      upload_rc=0
      echo "Yedek yükleme (gh release upload --clobber) başarılı: ${asset_name}"
    fi

    if [[ "$upload_rc" -eq 124 ]]; then
      UPLOAD_LAST_ERROR["$asset_name"]="upload timeout (${APK_UPLOAD_ATTEMPT_TIMEOUT})"
    elif [[ "$upload_rc" -ne 0 ]]; then
      UPLOAD_LAST_ERROR["$asset_name"]="upload API and gh release upload failed (attempt ${attempt})"
    else
      local verify_attempt=1 verified=0
      while (( verify_attempt <= 10 )); do
        sleep $(( verify_attempt * 3 ))
        remote_size=$(release_asset_size "$asset_name")
        if [[ -n "$remote_size" && "$remote_size" == "$local_size" ]] \
          && remote_asset_matches_local_sha "$file" "$asset_name"; then
          verified=1
          break
        fi
        echo "Post-upload doğrulama ${verify_attempt}/10 asset=${asset_name} api_size=${remote_size:-?}"
        verify_attempt=$((verify_attempt + 1))
      done
      if (( verified == 1 )); then
        echo "Asset doğrulandı: ${asset_name}"
        UPLOAD_OUTCOME["$asset_name"]="ok_uploaded"
        return 0
      fi
      UPLOAD_LAST_ERROR["$asset_name"]="post-upload size/SHA256 verify failed (api_size=${remote_size:-?}, local_size=${local_size})"
    fi

    if (( attempt < max )); then
      echo "Tekrar ${delay}s sonra..."
      sleep "$delay"
      delay=$((delay + 10))
      if (( delay > 45 )); then delay=45; fi
    fi
    attempt=$((attempt + 1))
  done

  echo "::error::Asset yüklenemedi (${max} deneme): ${asset_name} — ${UPLOAD_LAST_ERROR[$asset_name]:-unknown}"
  UPLOAD_OUTCOME["$asset_name"]="failed"
  return 1
}

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

final_verify_release() {
  local missing=0
  if ! gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
    echo "::error::apk-latest release mevcut değil: tag=${TAG}"
    return 1
  fi
  echo "apk-latest release mevcut: tag=${TAG}"
  echo "Release asset isimleri (GitHub API):"
  list_release_asset_names | sed 's/^/  - /'

  local json
  json=$(release_json) || {
    echo "::error::Release JSON okunamadı"
    return 1
  }

  for asset_name in "${REQUIRED_ASSETS[@]}"; do
    local size
    size=$(printf '%s' "$json" | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for a in data.get('assets') or []:
    if a.get('name') == name:
        print(int(a.get('size') or 0))
        break
" "$asset_name")
    if [[ -z "$size" || "$size" -le 0 ]]; then
      echo "::error::Eksik veya boş asset: ${asset_name} (tag=${TAG})"
      missing=$((missing + 1))
    else
      echo "Asset OK: ${asset_name} (${size} bytes)"
    fi
  done

  local base="https://github.com/${REPO}/releases/download/${TAG}"
  for asset_name in "${REQUIRED_ASSETS[@]}"; do
    local url="${base}/${asset_name}"
    local code
    code=$(curl -sS -o /dev/null -w '%{http_code}' -L \
      -H 'Cache-Control: no-cache' \
      "${url}?final_verify=${GITHUB_RUN_ID:-0}" || echo "000")
    if [[ "$code" == "200" ]]; then
      echo "Download URL HTTP 200: ${url}"
    else
      echo "::error::Download URL HTTP ${code}: ${url}"
      missing=$((missing + 1))
    fi
  done

  (( missing == 0 ))
}

set -e
ensure_release
set +e

upload_failures=0
for asset_name in "${REQUIRED_ASSETS[@]}"; do
  if ! upload_one_asset "$asset_name"; then
    upload_failures=$((upload_failures + 1))
  fi
done

echo "--- Upload özet (tag=${TAG}) ---"
for asset_name in "${REQUIRED_ASSETS[@]}"; do
  echo "  ${asset_name}: ${UPLOAD_OUTCOME[$asset_name]:-unknown}"
  if [[ "${UPLOAD_OUTCOME[$asset_name]:-}" == failed ]]; then
    echo "    last_error: ${UPLOAD_LAST_ERROR[$asset_name]:-?}"
  fi
done

if (( upload_failures > 0 )); then
  echo "::error::apk-latest yükleme başarısız (${upload_failures} asset). Tag=${TAG} repo=${REPO}"
  for asset_name in "${REQUIRED_ASSETS[@]}"; do
    if [[ "${UPLOAD_OUTCOME[$asset_name]:-}" == failed ]]; then
      echo "::error::  ${asset_name}: ${UPLOAD_LAST_ERROR[$asset_name]:-no detail}"
    fi
  done
  exit 1
fi

set -e
gh release edit "$TAG" \
  --repo "$REPO" \
  --title "$TITLE" \
  --notes-file "$NOTES_PATH" \
  --target "$TARGET_SHA"

if ! final_verify_release; then
  echo "::error::apk-latest son doğrulama başarısız (tag=${TAG})"
  exit 1
fi

echo "apk-latest release assets successfully updated and verified"
