#!/usr/bin/env bash
# Paralel mod — tek ekran özet (agent şimdi · cihaz sonra).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"

VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Canlifal — paralel mod (${VERSION})                              ║
╚══════════════════════════════════════════════════════════════════╝

RELEASE READY: NO · Cihaz P0/P1 sonucu SONRA · Agent prep DEVAM

APK: ${APK_URL}

┌─ Agent (şimdi) ─────────────────────────────────────────────────┐
│ bash scripts/devam-et.sh               # agent devam (tam)       │
│ bash scripts/print-paralel-mod.sh      # bu özet                   │
│ bash scripts/p1-prep-go.sh             # P1 checklist GO          │
│ bash scripts/p2-prep-go.sh             # Play Store GO             │
│ bash scripts/p2-prep-all.sh            # Play Console print paketi │
│ bash scripts/print-agent-prep-status.sh # prep envanter          │
│ bash scripts/print-go-commands.sh      # GO indeks               │
│ bash scripts/print-release-blockers.sh # RELEASE READY engelleri │
│ bash scripts/print-play-upload-day-checklist.sh # yükleme günü   │
└──────────────────────────────────────────────────────────────────┘

┌─ Cihaz (sonra) ─────────────────────────────────────────────────┐
│ bash scripts/cihaz-sonra.sh                                       │
│ bash scripts/p0-go.sh → user-test-start.sh p0                     │
│ bash scripts/on-p0-pass.sh → p1-go.sh → on-p1-pass.sh           │
└──────────────────────────────────────────────────────────────────┘

Hesaplar: cursor.test.* (danışan) · cursor.host.* (falcı)
Şifre: CursorTest!1786235468

Detay: docs/KALAN_ISLER.md · docs/RELEASE_USER_NEXT_STEPS.md
EOF

echo ""
bash "$ROOT/scripts/release-remaining-status.sh" 2>&1 | grep -E '^(──|Durum:|  M|  Gate|Kod/CI|Sonraki)' | head -18 || true
