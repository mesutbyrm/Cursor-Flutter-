#!/usr/bin/env bash
# Devam et — prep ✅ ise hızlı durum; --full ile tam yenileme; --api ile API raporları.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mode="fast"
for arg in "$@"; do
  case "$arg" in
    --full) mode="full" ;;
    --api) mode="api" ;;
  esac
done

case "$mode" in
  full)
    exec bash "$ROOT/scripts/kalan-isler-agent.sh"
    ;;
  api)
    exec bash "$ROOT/scripts/agent-bitti.sh" --api
    ;;
  fast)
    if bash "$ROOT/scripts/agent-prep-tamam.sh" >/dev/null 2>&1; then
      exec bash "$ROOT/scripts/agent-bitti.sh"
    fi
    exec bash "$ROOT/scripts/kalan-isler-agent.sh"
    ;;
esac
