#!/usr/bin/env bash
# GitHub repo temizliği: birleşmiş PR'ları kapat, kullanılmayan cursor/* dallarını sil.
# Kullanım:
#   DRY_RUN=1 bash scripts/github-cleanup.sh   # rapor only
#   bash scripts/github-cleanup.sh             # uygula (GH_TOKEN veya gh auth gerekir)
#
# Kurallar:
#   - Yeni PR AÇMAZ
#   - Review isteği oluşturmaz
#   - main ve ACTIVE_CURSOR_BRANCHES korunur

set -euo pipefail

REPO="${GITHUB_REPOSITORY:-mesutbyrm/Cursor-Flutter-}"
BASE_BRANCH="${BASE_BRANCH:-main}"
DRY_RUN="${DRY_RUN:-0}"
KEEP_BRANCHES="${KEEP_BRANCHES:-main,master}"
# Virgülle ayrılmış korunan cursor dalları (aktif geliştirme)
ACTIVE_CURSOR="${ACTIVE_CURSOR_BRANCHES:-}"

REPORT_DIR="${REPORT_DIR:-docs}"
REPORT_FILE="${REPORT_DIR}/GITHUB_CLEANUP_REPORT.md"
CLOSED_LOG="/tmp/github-cleanup-closed-prs.txt"
DELETED_LOG="/tmp/github-cleanup-deleted-branches.txt"
REMAINING_LOG="/tmp/github-cleanup-remaining-prs.txt"
ACTIVE_LOG="/tmp/github-cleanup-active-branches.txt"

: >"$CLOSED_LOG"
: >"$DELETED_LOG"
: >"$REMAINING_LOG"
: >"$ACTIVE_LOG"

log() { printf '%s\n' "$*"; }

require_gh() {
  if ! command -v gh >/dev/null 2>&1; then
    log "ERROR: gh CLI bulunamadı."
    exit 1
  fi
  if ! gh auth status >/dev/null 2>&1; then
    if [[ -z "${GH_TOKEN:-}" && -z "${GITHUB_TOKEN:-}" ]]; then
      log "ERROR: gh oturumu yok. GH_TOKEN veya gh auth login gerekir."
      exit 1
    fi
    export GH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
  fi
}

is_protected_branch() {
  local branch="$1"
  local keep
  IFS=',' read -ra KEEPS <<<"$KEEP_BRANCHES,$ACTIVE_CURSOR"
  for keep in "${KEEPS[@]}"; do
    [[ -z "$keep" ]] && continue
    if [[ "$branch" == "$keep" ]]; then
      return 0
    fi
  done
  return 1
}

close_pr() {
  local num="$1"
  local reason="$2"
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY  close PR #$num — $reason"
  else
    gh pr close "$num" --repo "$REPO" \
      --comment "Otomatik kapatma (github-cleanup): $reason" 2>/dev/null \
      || gh pr close "$num" --repo "$REPO" 2>/dev/null \
      || true
  fi
  echo "#$num|$reason" >>"$CLOSED_LOG"
}

delete_remote_branch() {
  local branch="$1"
  local reason="$2"
  if is_protected_branch "$branch"; then
    log "SKIP delete (protected): $branch"
    echo "$branch|protected" >>"$ACTIVE_LOG"
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    log "DRY  delete branch $branch — $reason"
  else
    gh api -X DELETE "/repos/${REPO}/git/refs/heads/${branch}" 2>/dev/null \
      || git push origin --delete "$branch" 2>/dev/null \
      || log "WARN could not delete $branch"
  fi
  echo "$branch|$reason" >>"$DELETED_LOG"
}

fetch_refs() {
  log "Fetching origin..."
  git fetch origin --prune
  git checkout "$BASE_BRANCH" 2>/dev/null || git checkout -B "$BASE_BRANCH" "origin/$BASE_BRANCH"
  git pull --ff-only origin "$BASE_BRANCH" 2>/dev/null || true
}

close_merged_prs() {
  log "=== Açık PR'lar taranıyor ==="
  local pr_json
  pr_json="$(gh pr list --repo "$REPO" --state open --limit 500 \
    --json number,title,headRefName,baseRefName,isDraft,updatedAt)"

  local count
  count="$(echo "$pr_json" | jq 'length')"
  log "Açık PR sayısı: $count"

  echo "$pr_json" | jq -c '.[]' | while read -r pr; do
    local num head base title draft updated
    num="$(echo "$pr" | jq -r '.number')"
    head="$(echo "$pr" | jq -r '.headRefName')"
    base="$(echo "$pr" | jq -r '.baseRefName')"
    title="$(echo "$pr" | jq -r '.title')"
    draft="$(echo "$pr" | jq -r '.isDraft')"
    updated="$(echo "$pr" | jq -r '.updatedAt')"

    # head zaten base'e merge edilmiş mi?
    if git show-ref --verify --quiet "refs/remotes/origin/${head}" 2>/dev/null; then
      if git merge-base --is-ancestor "origin/${head}" "origin/${base}" 2>/dev/null; then
        close_pr "$num" "head \`${head}\` zaten \`${base}\` içinde (merged ancestor)"
        continue
      fi
    else
      # dal silinmiş — PR yetim
      close_pr "$num" "head branch \`${head}\` remote'da yok (orphan PR)"
      continue
    fi

    # PR numarası main geçmişinde merge commit olarak var mı?
    if git log "origin/${base}" --oneline --grep="Merge pull request #${num}" | grep -q .; then
      close_pr "$num" "PR #${num} main geçmişinde merge edilmiş görünüyor"
      continue
    fi

    # Eski draft PR (>60 gün güncellenmemiş)
    local updated_epoch now_epoch age_days
    updated_epoch="$(date -d "$updated" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$updated" +%s 2>/dev/null || echo 0)"
    now_epoch="$(date +%s)"
    age_days=$(( (now_epoch - updated_epoch) / 86400 ))
    if [[ "$draft" == "true" && "$age_days" -gt 60 ]]; then
      close_pr "$num" "draft PR ${age_days} gündür güncellenmedi (abandoned)"
      continue
    fi

    echo "#$num|$head|$base|draft=$draft|$title" >>"$REMAINING_LOG"
  done
}

delete_merged_cursor_branches() {
  log "=== Birleşmiş cursor/* dalları siliniyor ==="
  local branch
  while read -r branch; do
    [[ -z "$branch" ]] && continue
    [[ "$branch" != cursor/* ]] && continue
    if is_protected_branch "${branch#cursor/}" || is_protected_branch "$branch"; then
      echo "$branch|active/protected" >>"$ACTIVE_LOG"
      continue
    fi
    # Açık PR head'i ise silme
    if grep -q "|${branch}|" "$REMAINING_LOG" 2>/dev/null; then
      echo "$branch|open PR head" >>"$ACTIVE_LOG"
      continue
    fi
    if git merge-base --is-ancestor "origin/${branch}" "origin/${BASE_BRANCH}" 2>/dev/null; then
      delete_remote_branch "$branch" "merged into ${BASE_BRANCH}"
    fi
  done < <(git branch -r | sed 's|^[* ]*origin/||' | grep '^cursor/' | sort -u)
}

delete_local_merged_branches() {
  log "=== Yerel birleşmiş cursor dalları ==="
  local b
  while read -r b; do
    [[ -z "$b" ]] && continue
    if [[ "$DRY_RUN" == "1" ]]; then
      log "DRY  local branch -d $b"
    else
      git branch -d "$b" 2>/dev/null || true
    fi
  done < <(git branch --merged "$BASE_BRANCH" | sed 's/^[* ]*//' | grep '^cursor/' || true)
}

write_report() {
  mkdir -p "$REPORT_DIR"
  local closed_count deleted_count remaining_count active_count
  closed_count="$(wc -l <"$CLOSED_LOG" | tr -d ' ')"
  deleted_count="$(wc -l <"$DELETED_LOG" | tr -d ' ')"
  remaining_count="$(wc -l <"$REMAINING_LOG" | tr -d ' ')"
  active_count="$(wc -l <"$ACTIVE_LOG" | tr -d ' ')"

  cat >"$REPORT_FILE" <<EOF
# GitHub Temizlik Raporu

Oluşturulma: $(date -u +"%Y-%m-%d %H:%M UTC")
Mod: $([[ "$DRY_RUN" == "1" ]] && echo "DRY RUN" || echo "APPLIED")
Repo: \`$REPO\`
Base: \`$BASE_BRANCH\`

## Özet

| Metrik | Adet |
|--------|------|
| Kapatılan PR | $closed_count |
| Silinen remote dal | $deleted_count |
| Kalan açık PR | $remaining_count |
| Korunan / aktif dal | $active_count |

## Kapatılan PR'lar

| PR | Neden |
|----|-------|
$(if [[ -s "$CLOSED_LOG" ]]; then sed 's/|/ | /' "$CLOSED_LOG" | sed 's/^#/#/' | sed 's/^/| /' | sed 's/$/ |/'; else echo "| — | — |"; fi)

## Silinen dallar (cursor/*)

| Dal | Neden |
|-----|-------|
$(if [[ -s "$DELETED_LOG" ]]; then sed 's/|/ | /' "$DELETED_LOG" | sed 's/^/| /' | sed 's/$/ |/'; else echo "| — | — |"; fi)

## Kalan açık PR'lar

| PR | Head | Base | Not |
|----|------|------|-----|
$(if [[ -s "$REMAINING_LOG" ]]; then sed 's/|/ | /g' "$REMAINING_LOG" | sed 's/^#/#/' | sed 's/^/| /' | sed 's/$/ |/'; else echo "| — | — | — | — |"; fi)

## Aktif / korunan dallar

$(if [[ -s "$ACTIVE_LOG" ]]; then sed 's/|/ — /' "$ACTIVE_LOG" | sed 's/^/- /'; else echo "- \`main\` (varsayılan)"; fi)

## İş akışı kuralları

- PR otomatik **açılmaz**
- Geliştirme doğrudan \`main\` (veya \`ACTIVE_CURSOR_BRANCHES\`) üzerinde
- Bu betik haftalık CI veya \`workflow_dispatch\` ile çalıştırılır
EOF

  log "Rapor: $REPORT_FILE"
}

main() {
  cd "$(git rev-parse --show-toplevel)"
  require_gh
  fetch_refs
  close_merged_prs
  delete_merged_cursor_branches
  delete_local_merged_branches
  write_report
  log "=== Tamamlandı ==="
  log "Kapatılan PR: $(wc -l <"$CLOSED_LOG")"
  log "Silinen dal: $(wc -l <"$DELETED_LOG")"
  log "Kalan PR: $(wc -l <"$REMAINING_LOG")"
}

main "$@"
