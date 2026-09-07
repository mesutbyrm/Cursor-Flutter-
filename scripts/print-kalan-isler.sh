#!/usr/bin/env bash
# KALAN_ISLER.md terminal çıktısı.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec cat "$ROOT/docs/KALAN_ISLER.md"
