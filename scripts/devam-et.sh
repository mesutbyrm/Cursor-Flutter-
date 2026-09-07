#!/usr/bin/env bash
# Devam et — isteğe bağlı API yenileme (agent prep ✅ tamam).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
exec bash "$ROOT/scripts/kalan-isler-agent.sh"
