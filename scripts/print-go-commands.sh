#!/usr/bin/env bash
# Tüm GO / prep giriş betikleri — tek indeks.
set -euo pipefail

cat <<'EOF'
=== Canlifal — GO / prep komutları ===

Paralel mod:
  bash scripts/devam-et.sh                 # agent devam (tam API + P1/P2 prep)
  bash scripts/print-paralel-mod.sh        # tek ekran özet
  bash scripts/print-release-blockers.sh   # RELEASE READY engelleri
  bash scripts/kalan-isler.sh              # durum tablosu

Cihaz (sonra):
  bash scripts/basla.sh                    # canlı durum + devir teslim
  bash scripts/cihaz-sonra.sh              # cihaz akış özeti
  bash scripts/p0-go.sh                    # Psychic P0 GO
  bash scripts/user-test-start.sh p0       # P0 checklist

P0 sonrası:
  bash scripts/on-p0-pass.sh               # P0 PASS kaydı → P1
  bash scripts/p1-go.sh                    # P1 cihaz GO
  bash scripts/p1-prep-go.sh               # P1 checklist (ön, P0 kaydı sonra)

P1 sonrası:
  bash scripts/on-p1-pass.sh               # P1 PASS kaydı
  bash scripts/on-release-ready-candidate.sh

Agent P2 (şimdi):
  bash scripts/p2-prep-go.sh               # Play Store GO
  bash scripts/p2-prep-all.sh              # tam Console print paketi
  bash scripts/print-play-console-prep-index.sh

Yükleme günü (P0+P1 PASS):
  bash scripts/print-play-upload-day-checklist.sh
  bash scripts/p2-go.sh
  bash scripts/print-ci-aab-steps.sh

Agent prep envanter:
  bash scripts/print-agent-prep-status.sh
  bash scripts/agent-prep-tamam.sh

Sonuç kaydı:
  bash scripts/record-user-test-result.sh p0 PASS|FAIL
  bash scripts/on-p0-fail.sh "not"
EOF
