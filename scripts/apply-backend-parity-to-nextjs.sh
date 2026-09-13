#!/usr/bin/env bash
# backend-parity/nextjs_space → fortune_telling_platform/nextjs_space
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${ROOT}/backend-parity/nextjs_space"
DEST="${1:-${ROOT}/nextjs_space}"

if [[ ! -d "$SRC/app/api" ]]; then
  echo "Kaynak yok: $SRC/app/api" >&2
  exit 1
fi
if [[ ! -d "$DEST" ]]; then
  echo "Hedef nextjs_space bulunamadı: $DEST" >&2
  echo "Kullanım: $0 /path/to/fortune_telling_platform/nextjs_space" >&2
  exit 1
fi

shopt -s globstar nullglob
count=0
while IFS= read -r -d '' f; do
  rel="${f#"$SRC/"}"
  out="$DEST/$rel"
  mkdir -p "$(dirname "$out")"
  if [[ -f "$out" ]]; then
    echo "ATLA (mevcut): $rel"
  else
    cp "$f" "$out"
    echo "EKLENDI: $rel"
    count=$((count + 1))
  fi
done < <(find "$SRC" -type f -print0)

echo "Tamam. Yeni dosya: $count"
