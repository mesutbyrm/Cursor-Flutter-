#!/usr/bin/env bash
# Agent kapanış durumu — mobil kod değişikliği yok; kullanıcı cihaz testi sırada.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/release-remaining-status.sh"
