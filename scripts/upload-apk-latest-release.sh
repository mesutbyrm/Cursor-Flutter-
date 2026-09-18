#!/usr/bin/env bash
# apk-latest release — gh CLI, dosya bazlı timeout + retry (büyük APK).
set -uo pipefail

TAG="${APK_LATEST_TAG:-apk-latest}"
TITLE="${RELEASE_TITLE:?RELEASE_TITLE gerekli}"
NOTES_PATH="${NOTES_PATH:?NOTES_PATH gerekli}"
TARGET_SHA="${BUILD_SHA:-${GITHUB_SHA:?GITHUB_SHA gerekli}}"
REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY gerekli}"

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

sha256_file() {
  sha256sum "$1" | awk '{print $1}'
}

release_asset_id() {
  local asset_name="$1"
  gh release view "$TAG" --repo "$REPO" --json assets 2>/dev/null \
    | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for a in data.get('assets') or []:
    if a.get('name') == name:
        print(a.get('id') or '')
        break
" "$asset_name" 2>/dev/null || true
}

delete_release_asset() {
  local asset_name="$1"
  local asset_id
  asset_id=$(release_asset_id "$asset_name")
  if [[ -z "$asset_id" ]]; then
    return 0
  fi
  echo "Mevcut release asset siliniyor: ${asset_name} (id=${asset_id})"
  gh api -X DELETE "repos/${REPO}/releases/assets/${asset_id}" >/dev/null
}

download_release_asset_bytes() {
  local asset_name="$1"
  local dest="$2"
  local dir file
  dir=$(dirname "$dest")
  file=$(basename "$dest")
  mkdir -p "$dir"
  rm -f "$dest"
  if ! gh release download "$TAG" --repo "$REPO" -p "$asset_name" -D "$dir" --clobber 2>/dev/null; then
    return 1
  fi
  if [[ -f "$dir/$asset_name" ]]; then
    mv -f "$dir/$asset_name" "$dest"
  fi
  if [[ ! -s "$dest" ]]; then
    return 1
  fi
  # APK (zip) magic
  if [[ "$(head -c 2 "$dest" || true)" != "PK" ]]; then
    echo "::warning::İndirilen dosya APK imzası taşımıyor: ${asset_name}"
    return 1
  fi
}

remote_asset_matches_local_sha() {
  local file="$1"
  local asset_name="$2"
  local tmp
  tmp=$(mktemp)
  if ! download_release_asset_bytes "$asset_name" "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    return 1
  fi
  local local_sha remote_sha
  local_sha=$(sha256_file "$file")
  remote_sha=$(sha256_file "$tmp")
  rm -f "$tmp"
  if [[ "$local_sha" == "$remote_sha" ]]; then
    return 0
  fi
  echo "Release asset SHA farklı (yeniden yüklenecek): ${asset_name}"
  echo "  local SHA256=${local_sha}"
  echo "  remote SHA256=${remote_sha}"
  return 1
}

release_asset_size() {
  local asset_name="$1"
  gh release view "$TAG" --repo "$REPO" --json assets 2>/dev/null \
    | python3 -c "
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

run_gh_upload() {
  local file="$1"
  if command -v timeout >/dev/null 2>&1; then
    timeout "$APK_UPLOAD_ATTEMPT_TIMEOUT" gh release upload "$TAG" "$file" --clobber --repo "$REPO"
    return $?
  fi
  echo "::warning::timeout komutu yok — upload süre sınırı olmadan deneniyor"
  gh release upload "$TAG" "$file" --clobber --repo "$REPO"
}

upload_one_asset() {
  local file="$1"
  local asset_name
  asset_name=$(basename "$file")

  if [[ ! -f "$file" || ! -s "$file" ]]; then
    echo "::warning::Yerel APK yok veya boş, atlanıyor: $asset_name"
    UPLOAD_OUTCOME["$asset_name"]="skipped_missing_local"
    return 0
  fi

  local local_size remote_size
  local_size=$(stat -c%s "$file")

  if [[ "${APK_FORCE_UPLOAD:-0}" != "1" ]]; then
    remote_size=$(release_asset_size "$asset_name")
    if [[ -n "$remote_size" && "$remote_size" -gt 0 && "$remote_size" == "$local_size" ]]; then
      if remote_asset_matches_local_sha "$file" "$asset_name"; then
        echo "Asset zaten release'ta (boyut + SHA256 eşleşiyor, yükleme atlandı): ${asset_name} (${local_size} bytes)"
        UPLOAD_OUTCOME["$asset_name"]="ok_existing"
        return 0
      fi
      echo "Boyut eşleşiyor ancak içerik (SHA256) farklı — yeniden yüklenecek: ${asset_name}"
    fi
    if [[ -n "$remote_size" && "$remote_size" -gt 0 && "$remote_size" != "$local_size" ]]; then
      echo "Mevcut asset boyutu farklı (remote=${remote_size}, local=${local_size}) — yeniden yüklenecek: ${asset_name}"
    fi
  fi

  local needs_replace=1
  if [[ "${UPLOAD_OUTCOME[$asset_name]:-}" == ok_existing ]]; then
    needs_replace=0
  fi
  if (( needs_replace == 1 )); then
    delete_release_asset "$asset_name"
    sleep 3
  fi

  local attempt=1
  local delay="$APK_UPLOAD_RETRY_BASE_SEC"
  local max="$APK_UPLOAD_RETRIES"
  local rc=0

  while (( attempt <= max )); do
    echo "Yükleme denemesi ${attempt}/${max}: ${asset_name} (${local_size} bytes, deneme timeout=${APK_UPLOAD_ATTEMPT_TIMEOUT})"
    set +e
    run_gh_upload "$file"
    rc=$?
    set -e

    if [[ "$rc" -eq 0 ]]; then
      local verify_attempt=1
      local verified=0
      while (( verify_attempt <= 8 )); do
        sleep $(( verify_attempt * 5 ))
        remote_size=$(release_asset_size "$asset_name")
        if [[ -n "$remote_size" && "$remote_size" == "$local_size" ]] \
          && remote_asset_matches_local_sha "$file" "$asset_name"; then
          verified=1
          break
        fi
        echo "Post-upload doğrulama ${verify_attempt}/8 (boyut=${remote_size:-?}, beklenen=${local_size})..."
        verify_attempt=$((verify_attempt + 1))
      done
      if (( verified == 1 )); then
        echo "Asset yüklendi ve doğrulandı (boyut + SHA256): ${asset_name}"
        UPLOAD_OUTCOME["$asset_name"]="ok_uploaded"
        return 0
      fi
      echo "::warning::Upload exit 0 ama release SHA256/boyut doğrulanamadı (remote=${remote_size:-?}, local=${local_size})"
      delete_release_asset "$asset_name"
      rc=1
    elif [[ "$rc" -eq 124 ]]; then
      echo "::warning::Upload zaman aşımı (${APK_UPLOAD_ATTEMPT_TIMEOUT}): ${asset_name}"
    else
      echo "::warning::Upload başarısız (exit=${rc}): ${asset_name}"
    fi

    if (( attempt < max )); then
      echo "Tekrar ${delay}s sonra..."
      sleep "$delay"
      if (( delay < 45 )); then
        delay=$((delay + 10))
      fi
    fi
    attempt=$((attempt + 1))
  done

  echo "::error::Asset yüklenemedi (${max} deneme): ${asset_name}"
  UPLOAD_OUTCOME["$asset_name"]="failed"
  return 1
}

verify_release_has_assets() {
  local missing=0
  local json
  json=$(gh release view "$TAG" --repo "$REPO" --json assets 2>/dev/null) || {
    echo "::error::Release görüntülenemedi: $TAG"
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
      echo "::error::Release'ta eksik veya boş asset: ${asset_name}"
      missing=$((missing + 1))
    else
      echo "Release asset OK: ${asset_name} (${size} bytes)"
    fi
  done

  (( missing == 0 ))
}

verify_download_urls() {
  local base="https://github.com/${REPO}/releases/download/${TAG}"
  local attempt=1
  local max=4

  while (( attempt <= max )); do
    local failed=0
    for asset_name in "${REQUIRED_ASSETS[@]}"; do
      local url="${base}/${asset_name}"
      local code
      code=$(curl -sS -o /dev/null -w '%{http_code}' -L \
        -H 'Cache-Control: no-cache' \
        "${url}?ci_verify=${GITHUB_RUN_ID:-0}-${attempt}" || echo "000")
      if [[ "$code" == "200" ]]; then
        echo "İndirme URL OK (${code}): ${url}"
      else
        echo "İndirme URL HTTP ${code}: ${url} (deneme ${attempt}/${max})"
        failed=$((failed + 1))
      fi
    done
    if (( failed == 0 )); then
      return 0
    fi
    if (( attempt < max )); then
      sleep 15
    fi
    attempt=$((attempt + 1))
  done

  echo "::error::apk-latest indirme URL'leri doğrulanamadı"
  return 1
}

set -e
ensure_release
set +e

upload_failures=0
for asset in "${REQUIRED_ASSETS[@]}"; do
  if ! upload_one_asset "$asset"; then
    upload_failures=$((upload_failures + 1))
    echo "::warning::${asset} yükleme başarısız — diğer APK denenmeye devam ediliyor"
  fi
done

set -e
gh release edit "$TAG" \
  --repo "$REPO" \
  --title "$TITLE" \
  --notes-file "$NOTES_PATH" \
  --target "$TARGET_SHA"

echo "--- Upload özet ---"
for asset_name in "${REQUIRED_ASSETS[@]}"; do
  echo "  ${asset_name}: ${UPLOAD_OUTCOME[$asset_name]:-unknown}"
done

verify_ok=0
if verify_release_has_assets; then
  verify_ok=1
else
  echo "::warning::Release asset listesi doğrulaması eksik (CDN gecikmesi olabilir)"
fi

url_ok=0
if verify_download_urls; then
  url_ok=1
else
  echo "::warning::CDN indirme URL doğrulaması başarısız (birkaç dakika gecikme normal)"
fi

if (( upload_failures > 0 )); then
  if [[ "${UPLOAD_OUTCOME[canlifal-mobile-release.apk]:-}" == ok_* ]] \
    && [[ "${UPLOAD_OUTCOME[canlifal-mobile-arm64-release.apk]:-}" == failed ]]; then
    echo "::error::Universal APK yüklendi ancak arm64 APK yüklenemedi. Universal silinmedi; workflow'u yeniden çalıştırın veya arm64'ü manuel yükleyin."
  else
    echo "::error::Bir veya daha fazla APK yüklenemedi (başarısız=${upload_failures}). Mevcut release asset'leri korundu."
  fi
  exit 1
fi

if (( verify_ok == 0 )); then
  echo "::error::Release'ta gerekli asset'ler doğrulanamadı"
  exit 1
fi

if (( url_ok == 0 )); then
  echo "::error::apk-latest indirme URL'leri doğrulanamadı"
  exit 1
fi

echo "apk-latest tamam: ${TITLE}"
