#!/usr/bin/env bash
# Play Console — tüm agent prep print betikleri (indeks).
set -euo pipefail

cat <<'EOF'
=== Play Console agent prep — print betikleri ===

Tam prep:     bash scripts/p2-prep-all.sh
Checklist:    bash scripts/play-store-checklist.sh
AAB readiness: bash scripts/play-aab-readiness.sh

Kopyala-yapıştır metinler:
  bash scripts/print-play-console-app-access.sh      # App access
  bash scripts/print-play-foreground-service-declaration.sh  # FGS
  bash scripts/print-play-data-safety-summary.sh     # Data safety
  bash scripts/print-play-content-rating-summary.sh  # Content rating (IARC)
  bash scripts/print-play-store-listing.sh           # Store listing taslak

CI / imza:
  bash scripts/play-keystore-secrets-cheatsheet.sh   # GitHub secrets
  bash scripts/print-ci-aab-steps.sh                 # Actions AAB adımları
  bash scripts/build-play-aab.sh                     # Yerel AAB (keystore)

Rehberler: docs/PLAY_STORE_AGENT_CHECKLIST.md · docs/P2_PLAY_STORE_START.md
EOF
