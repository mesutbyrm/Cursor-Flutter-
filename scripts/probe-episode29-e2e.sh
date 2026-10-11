#!/usr/bin/env bash
# Episode 29 E2E — canlifal.com (JWT gerekir; acceptance ile aynı secret'lar).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=acceptance-tests/lib.sh
source "$ROOT/scripts/acceptance-tests/lib.sh"

echo "=== Episode 29 probe ($BASE) ==="
EPISODE29_PROBE_ONLY=1 bash "$ROOT/scripts/acceptance-tests/api-acceptance.sh"
echo "Bitti — ayrıntı: docs/ACCEPTANCE_TEST_REPORT.md"
