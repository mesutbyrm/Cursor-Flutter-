#!/usr/bin/env bash
# P2 Play Store hazırlık — geriye dönük alias (p2-prep-go).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/p2-prep-go.sh"
