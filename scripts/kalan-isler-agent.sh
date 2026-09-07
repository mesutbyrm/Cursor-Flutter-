#!/usr/bin/env bash
# Agent kalan işler — isteğe bağlı API yenileme (prep ✅ tamam).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  Agent — API yenileme (prep ✅ tamam · isteğe bağlı)              ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

fail=0
run() {
  local t="$1" c="$2"
  echo "── $t ──"
  if eval "$c"; then
    echo ""
  else
    echo "⚠️  $t — kısmi uyarı"
    fail=$((fail + 1))
    echo ""
  fi
}

run "Canlı API + jeton + falcı" "bash '$ROOT/scripts/psychic-p0-prereqs.sh' 2>&1 | tail -8"
run "API otomasyon özeti" "bash '$ROOT/scripts/run-api-automation-summary.sh' 2>&1 | tail -10"
run "P1 checklist (ön hazırlık)" "bash '$ROOT/scripts/p1-prep-now.sh' 2>&1 | head -25"
run "P2 prep ALL (Play Store + FGS + keystore)" "bash '$ROOT/scripts/p2-prep-all.sh' 2>&1 | tail -40"
run "Play Console checklist" "bash '$ROOT/scripts/play-store-checklist.sh' 2>&1 | tail -18"

echo "══════════════════════════════════════════════════════════════════"
if [[ "$fail" -eq 0 ]]; then
  echo "✅ Agent paralel hazırlık tamam"
else
  echo "⚠️  Bazı adımlarda uyarı — yukarıya bakın"
fi
echo ""
if bash "$ROOT/scripts/agent-prep-tamam.sh" >/dev/null 2>&1; then
  echo "✅ Agent P2 prep paketi TAMAM — sırada kullanıcı adımları"
else
  echo "⏳ Agent prep paketi — bash scripts/agent-prep-tamam.sh"
fi
echo ""
echo "Kullanıcı:      bash scripts/kullanici-sonraki.sh"
echo "P1 prep GO:     bash scripts/p1-prep-go.sh"
echo "P2 prep GO:     bash scripts/p2-prep-go.sh"
echo "Agent prep:     bash scripts/print-agent-prep-status.sh"
echo "Prep tamam?:   bash scripts/agent-prep-tamam.sh"
echo "Upload günü:    bash scripts/print-play-upload-day-checklist.sh"
echo "Engeller:      bash scripts/print-release-blockers.sh"
echo "Paralel özet:   bash scripts/print-paralel-mod.sh"
echo "Devam et (hızlı): bash scripts/devam-et.sh"
echo "Tam yenileme:     bash scripts/devam-et.sh --full"
echo "P2 tek komut:   bash scripts/p2-prep-all.sh"
echo "Tam non-device: bash scripts/run-non-device-release-prep.sh"
echo "Durum tablosu:  bash scripts/kalan-isler.sh"
