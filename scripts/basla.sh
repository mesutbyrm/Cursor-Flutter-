#!/usr/bin/env bash
# Cihaz testi — tek komut başlangıç (canlı durum + devir teslim).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/user-handoff.sh"
