#!/usr/bin/env bash
# GitHub API olmadan yerel git durumundan temizlik raporu üretir.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

BASE="${1:-main}"
REPORT="docs/GITHUB_CLEANUP_REPORT.md"
MERGED_LIST="/tmp/local-merged-cursor.txt"
UNMERGED_LIST="/tmp/local-unmerged-cursor.txt"

git branch -r --merged "${BASE}" 2>/dev/null \
  | sed 's|^[* ]*origin/||' | grep '^cursor/' | sort -u >"$MERGED_LIST" || true
git branch -r --no-merged "${BASE}" 2>/dev/null \
  | sed 's|^[* ]*origin/||' | grep '^cursor/' | sort -u >"$UNMERGED_LIST" || true

MERGED_N=$(wc -l <"$MERGED_LIST" | tr -d ' ')
UNMERGED_N=$(wc -l <"$UNMERGED_LIST" | tr -d ' ')
LAST_MERGED_PR=$(git log "$BASE" --oneline --grep="Merge pull request" -1 | sed -n 's/.*#\([0-9]*\).*/\1/p' || echo "?")

mkdir -p docs
cat >"$REPORT" <<EOF
# GitHub Temizlik Raporu (yerel analiz)

Oluşturulma: $(date -u +"%Y-%m-%d %H:%M UTC")
Kaynak: yerel \`git branch -r\` (API erişimi gerekmez)
Base: \`${BASE}\`
Son birleşen PR (main geçmişi): **#${LAST_MERGED_PR}**

## Özet

| Metrik | Adet | Aksiyon |
|--------|------|---------|
| \`cursor/*\` merged into \`${BASE}\` | ${MERGED_N} | Remote silinebilir |
| \`cursor/*\` not merged | ${UNMERGED_N} | İncele / kapat veya main'e al |
| Aktif geliştirme dalı | \`main\` | Koru |

## Silinmeye aday remote dallar (merged)

\`\`\`
$(head -50 "$MERGED_LIST")
$( [[ "$MERGED_N" -gt 50 ]] && echo "... ve $((MERGED_N - 50)) dal daha" )
\`\`\`

## Birleşmemiş cursor dalları (inceleme gerekir)

\`\`\`
$(cat "$UNMERGED_LIST")
\`\`\`

## Bilinen eski açık PR'lar (manuel/CI kapatma)

\`docs/OPEN_PRS_TRIAGE.md\` — #1–3, 6, 16–17, 19, 21, 24, 33, 37, 62–64 main'de; kapatılmalı.

## Uygulama

\`\`\`bash
# CI (önerilen)
# Actions → GitHub cleanup → Run workflow

# Yerel (GH_TOKEN ile)
DRY_RUN=1 bash scripts/github-cleanup.sh
bash scripts/github-cleanup.sh
\`\`\`

## İş akışı

- PR otomatik açılmaz
- Geliştirme doğrudan \`main\` üzerinde
- Haftalık \`github-cleanup.yml\` birleşmiş PR/dalları temizler
EOF

echo "Wrote $REPORT (merged=$MERGED_N, unmerged=$UNMERGED_N)"
