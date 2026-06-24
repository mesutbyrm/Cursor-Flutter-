#!/usr/bin/env bash
# Yerel analyze — yalnızca ERROR satırlarını dosyaya yazar.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-/workspace/analyze-errors.txt}"
bash "$ROOT/scripts/dart-analyze-gate.sh" >/dev/null || true
rg '^\s*error\s+-' /tmp/canlifal-analyze.txt | head -30 > "$OUT" || true
wc -l < "$OUT" >> "$OUT"
