#!/usr/bin/env bash
# GitHub Actions depolama temizliği: artifact, cache, eski APK release'leri.
# Kullanım:
#   DRY_RUN=1 bash scripts/ci-actions-cleanup.sh
#   bash scripts/ci-actions-cleanup.sh
#   KEEP_RELEASE_TAGS=apk-latest bash scripts/ci-actions-cleanup.sh

set -euo pipefail

REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
DRY_RUN="${DRY_RUN:-0}"
KEEP_RELEASE_TAGS="${KEEP_RELEASE_TAGS:-apk-latest}"
PER_PAGE="${PER_PAGE:-100}"

log() { printf '%s\n' "$*"; }

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    log "ERROR: gh CLI bulunamadı."
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
    if [[ -z "${GH_TOKEN:-}" ]]; then
      log "ERROR: gh oturumu yok."
      exit 1
    fi
  fi
}

delete_all_artifacts() {
  log "=== Workflow artifact'ları siliniyor ==="
  local page=1 deleted=0 total_bytes=0
  while true; do
    local json count
    json="$(gh api "repos/${REPO}/actions/artifacts?per_page=${PER_PAGE}&page=${page}" 2>/dev/null || echo '{"artifacts":[]}')"
    count="$(echo "$json" | jq '.artifacts | length')"
    [[ "$count" -eq 0 ]] && break
    while read -r row; do
      [[ -z "$row" ]] && continue
      local id name size expired
      id="$(echo "$row" | jq -r '.id')"
      name="$(echo "$row" | jq -r '.name')"
      size="$(echo "$row" | jq -r '.size_in_bytes')"
      expired="$(echo "$row" | jq -r '.expired')"
      if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY  artifact #$id ($name, ${size}B, expired=$expired)"
      else
        gh api -X DELETE "repos/${REPO}/actions/artifacts/${id}" >/dev/null 2>&1 \
          && log "DEL  artifact #$id ($name)" \
          || log "WARN artifact #$id silinemedi"
      fi
      deleted=$((deleted + 1))
      total_bytes=$((total_bytes + size))
    done < <(echo "$json" | jq -c '.artifacts[]')
    page=$((page + 1))
    [[ "$count" -lt "$PER_PAGE" ]] && break
  done
  log "Artifact: $deleted adet (~$((total_bytes / 1048576)) MB)"
}

delete_all_caches() {
  log "=== Actions cache'leri siliniyor ==="
  local page=1 deleted=0 total_bytes=0
  while true; do
    local json count
    json="$(gh api "repos/${REPO}/actions/caches?per_page=${PER_PAGE}&page=${page}" 2>/dev/null || echo '{"actions_caches":[]}')"
    count="$(echo "$json" | jq '.actions_caches | length')"
    [[ "$count" -eq 0 ]] && break
    while read -r row; do
      [[ -z "$row" ]] && continue
      local id key size
      id="$(echo "$row" | jq -r '.id')"
      key="$(echo "$row" | jq -r '.key')"
      size="$(echo "$row" | jq -r '.size_in_bytes')"
      if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY  cache #$id ($key, ${size}B)"
      else
        gh api -X DELETE "repos/${REPO}/actions/caches/${id}" >/dev/null 2>&1 \
          && log "DEL  cache #$id ($key)" \
          || log "WARN cache #$id silinemedi"
      fi
      deleted=$((deleted + 1))
      total_bytes=$((total_bytes + size))
    done < <(echo "$json" | jq -c '.actions_caches[]')
    page=$((page + 1))
    [[ "$count" -lt "$PER_PAGE" ]] && break
  done
  log "Cache: $deleted adet (~$((total_bytes / 1048576)) MB)"
}

is_kept_release() {
  local tag="$1"
  local keep
  IFS=',' read -ra KEEPS <<<"$KEEP_RELEASE_TAGS"
  for keep in "${KEEPS[@]}"; do
    [[ -z "$keep" ]] && continue
    if [[ "$tag" == "$keep" ]]; then
      return 0
    fi
  done
  return 1
}

delete_old_apk_releases() {
  log "=== Eski APK release'leri temizleniyor (korunan: $KEEP_RELEASE_TAGS) ==="
  local deleted=0
  while read -r tag; do
    [[ -z "$tag" ]] && continue
    if is_kept_release "$tag"; then
      log "KEEP release $tag"
      continue
    fi
    # Yalnızca APK ile ilgili eski etiketler (apk-*, v*, test APK)
    if [[ "$tag" == apk-* ]] || [[ "$tag" == v* ]] || [[ "$tag" == *-7009 ]]; then
      if [[ "$DRY_RUN" == "1" ]]; then
        log "DRY  release $tag"
      else
        gh release delete "$tag" --repo "$REPO" --yes --cleanup-tag 2>/dev/null \
          && log "DEL  release $tag" \
          || log "WARN release $tag silinemedi"
      fi
      deleted=$((deleted + 1))
    fi
  done < <(gh release list --repo "$REPO" --limit 500 --json tagName --jq '.[].tagName')
  log "Release silindi: $deleted"
}

main() {
  require_gh
  log "Repo: $REPO | DRY_RUN=$DRY_RUN"
  delete_all_artifacts
  delete_all_caches
  delete_old_apk_releases
  log "=== CI depolama temizliği tamamlandı ==="
}

main "$@"
