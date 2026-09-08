#!/usr/bin/env bash
# P0 cihaz testi öncesi tek komut doğrulama.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/validate-pre-device-handoff.sh"
