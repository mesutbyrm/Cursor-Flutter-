#!/usr/bin/env bash
# Agent kapanış durumu — kalan işler + yol haritası.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/kalan-isler.sh"
