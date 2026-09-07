#!/usr/bin/env bash
# Psychic P0 — tam akış: önkoşul kontrolü → checklist yazdır.
# Jeton=0 ise admin adımlarını gösterir ve checklist'e geçmez.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Psychic P0 — tam akış ==="
echo ""

PREREQ=$("$ROOT/scripts/psychic-p0-prereqs.sh" 2>&1) || true
echo "$PREREQ"
echo ""

if echo "$PREREQ" | grep -q 'jeton=0'; then
  echo "── Admin jeton (zorunlu) ──"
  "$ROOT/scripts/admin-jeton-cheatsheet.sh" | head -25
  echo ""
  echo "Jeton ekledikten sonra:"
  echo "  bash scripts/after-admin-jeton.sh"
  echo "  bash scripts/psychic-p0-all.sh"
  exit 2
fi

if ! echo "$PREREQ" | grep -qE '✅ APK|✅ Danışan|✅ Falcı'; then
  echo "❌ Önkoşullar eksik — docs/PSYCHIC_P0_START.md"
  exit 1
fi

echo "── P0 checklist (2 telefon) ──"
"$ROOT/scripts/psychic-p0-checklist.sh"
echo ""
echo "Sonuç: Psychic P0 PASS veya FAIL — docs/PSYCHIC_P0_START.md"
