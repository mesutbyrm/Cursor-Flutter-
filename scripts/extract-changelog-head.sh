#!/usr/bin/env bash
# En üstteki CHANGELOG sürüm bloğunu markdown olarak yazar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHANGELOG="${ROOT}/mobile/CHANGELOG.md"
if [[ ! -f "$CHANGELOG" ]]; then
  echo "_CHANGELOG bulunamadı._"
  exit 0
fi
awk '
  /^## [0-9]/ {
    if (found++) exit
    print
    next
  }
  found { print }
' "$CHANGELOG"
