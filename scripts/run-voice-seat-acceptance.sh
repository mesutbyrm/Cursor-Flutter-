#!/usr/bin/env bash
# Sesli oda koltuk/presence/voice API kabul testleri (jeton gerektirmez).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export VOICE_PROBE_ROOM="${VOICE_PROBE_ROOM:-${MUSIC_PROBE_ROOM:-cmoohrbr}}"

echo "=== Voice seat acceptance (room=$VOICE_PROBE_ROOM) ==="
bash "$ROOT/scripts/acceptance-tests/api-voice-seat-phase.sh"
echo ""
echo "Rapor: docs/API_VOICE_SEAT_PHASE_REPORT.md"
