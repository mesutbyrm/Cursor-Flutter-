#!/usr/bin/env bash
# Phase 2 — showModalBottomSheet / showDialog envanter (lib, CDS altyapı hariç).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/docs/SHEET_MODAL_INVENTORY_PHASE2.md"
LIB="$ROOT/mobile/lib"

exclude() {
  case "$1" in
    *cds_bottom_sheet.dart|*cds_dialog.dart|*premium_bottom_sheet.dart) return 0 ;;
  esac
  return 1
}

{
  echo "# Sheet / modal envanter — Phase 2"
  echo ""
  echo "Oluşturma: \`$(date -u +%Y-%m-%dT%H:%M:%SZ)\`"
  echo ""
  echo "| Dosya | Satır | Çağrı |"
  echo "|-------|------:|-------|"
} > "$OUT"

total=0
while IFS= read -r line; do
  file="${line%%:*}"
  rest="${line#*:}"
  line_no="${rest%%:*}"
  if exclude "$file"; then continue; fi
  snippet="${rest#*:}"
  snippet="${snippet:0:80}"
  snippet="${snippet//|/\\|}"
  echo "| \`$file\` | $line_no | \`${snippet}...\` |" >> "$OUT"
  total=$((total + 1))
done < <(rg -n 'showModalBottomSheet|showDialog' "$LIB" --glob '*.dart' || true)

{
  echo ""
  echo "**Toplam ham çağrı:** $total"
  echo ""
  echo "Karar sütunları için \`docs/SHEET_MODAL_DECISIONS_PHASE2.md\` kullanılır."
} >> "$OUT"

echo "Wrote $OUT ($total entries)"
