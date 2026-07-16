#!/usr/bin/env bash
# apk-latest rolling release — gh CLI (publish-latest.sh ile aynı mantık).
# GET 403 / view hatalarında yanlışlıkla "create" denemesini önler.
set -euo pipefail

APK_PATH="${1:-canlifal-mobile-release.apk}"
TITLE="${2:-Canlifal APK}"
NOTES_PATH="${3:-/tmp/release_notes_min.md}"

REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY gerekli}"
export GH_TOKEN="${GH_RELEASE_PAT:-${GH_TOKEN:-${GITHUB_TOKEN:?GITHUB_TOKEN gerekli}}}"

gh_args=()
[[ -n "$REPO" ]] && gh_args=(--repo "$REPO")

if [[ ! -s "$APK_PATH" ]]; then
  echo "APK bulunamadı: $APK_PATH" >&2
  exit 1
fi

echo "=== apk-latest yükleme ==="
echo "Repo: ${REPO}"
echo "APK: $(ls -lh "$APK_PATH")"
command -v gh >/dev/null || { echo "gh CLI gerekli" >&2; exit 1; }
gh --version

release_http_code() {
  curl -sS -o /tmp/apk_latest_release.json -w "%{http_code}" \
    -H "Authorization: Bearer ${GH_TOKEN}" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/${REPO}/releases/tags/apk-latest"
}

HTTP_CODE="$(release_http_code)"
echo "Release GET HTTP ${HTTP_CODE}"

case "$HTTP_CODE" in
  200)
    echo "Mevcut apk-latest release — asset yükleniyor…"
    ;;
  404)
    echo "apk-latest release yok — oluşturuluyor…"
    create_args=(
      gh release create apk-latest "$APK_PATH"
      --title "$TITLE"
      --notes-file "$NOTES_PATH"
    )
    [[ -n "${GITHUB_SHA:-}" ]] && create_args+=(--target "$GITHUB_SHA")
    create_args+=("${gh_args[@]}")
    "${create_args[@]}"
    echo "apk-latest oluşturuldu: ${TITLE}"
    exit 0
    ;;
  403)
    echo "Hata: Release API 403 — GITHUB_TOKEN yetersiz olabilir." >&2
    echo "Çözüm: repo secret olarak GH_RELEASE_PAT (contents:write) ekleyin." >&2
    cat /tmp/apk_latest_release.json >&2 || true
    exit 1
    ;;
  *)
    echo "Hata: Release API beklenmeyen yanıt ${HTTP_CODE}" >&2
    cat /tmp/apk_latest_release.json >&2 || true
    exit 1
    ;;
esac

# Release mevcut — publish-latest.sh ile aynı (stderr gizleme yok)
gh release upload apk-latest "$APK_PATH" --clobber "${gh_args[@]}"

if gh release edit apk-latest --title "$TITLE" --notes-file "$NOTES_PATH" "${gh_args[@]}"; then
  echo "Release meta güncellendi"
else
  echo "Uyarı: release edit başarısız (asset yüklendi)" >&2
fi

echo "apk-latest yüklendi: ${TITLE}"
