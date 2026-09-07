#!/usr/bin/env bash
# Kullanıcı devir teslimi — canlı durum + kalan adımlar (= basla.sh).
# Kullanım: bash scripts/user-handoff.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

bash "$ROOT/scripts/print-p0-live-status.sh"
echo ""
exec bash "$ROOT/scripts/kullanici-sonraki.sh"
