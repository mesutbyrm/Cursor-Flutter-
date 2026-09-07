#!/usr/bin/env bash
# Devam et — agent paralel hazırlık (kalan-isler-agent alias).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/kalan-isler-agent.sh"
