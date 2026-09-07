#!/usr/bin/env bash
# USER_TEST_QUICK_REF.md terminal çıktısı.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec cat "$ROOT/docs/USER_TEST_QUICK_REF.md"
