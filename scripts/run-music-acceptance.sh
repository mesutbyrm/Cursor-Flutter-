#!/usr/bin/env bash
# Müzik API kabul testleri — api-music-phase + M7 probe (üretim).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export MUSIC_PROBE_ROOM="${MUSIC_PROBE_ROOM:-cmoohrbr}"

echo "=== Music acceptance (room=$MUSIC_PROBE_ROOM) ==="
bash "$ROOT/scripts/acceptance-tests/api-music-phase.sh"
echo ""
bash "$ROOT/scripts/probe-music-room.sh"
echo ""
echo "Raporlar: docs/API_MUSIC_PHASE_REPORT.md, docs/M7_MUSIC_SSE_CAPTURE.md"
