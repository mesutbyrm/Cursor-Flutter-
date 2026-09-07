#!/usr/bin/env bash
# P1 — genel platform 2-cihaz checklist (P0 PASS sonrası).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
VERSION="?"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  P1 — Genel platform 2-cihaz (${VERSION})                         ║
╚══════════════════════════════════════════════════════════════════╝

ÖNCE: Psychic P0 PASS — bash scripts/psychic-p0-all.sh

APK: ${APK_URL}
Hesaplar: docs/TEST_ACCOUNTS.md (A + B veya iki cihaz)

┌─────────────────────────────────────────────────────────────────┐
│ Alan                     │ PASS │ FAIL │ Not                      │
├─────────────────────────────────────────────────────────────────┤
│ Voice join/leave/rejoin  │ [ ]  │ [ ]  │ 2 cihaz aynı oda       │
│ Seat sync owner/viewer   │ [ ]  │ [ ]  │ Koltuk + mic           │
│ Gift + wallet + ranking  │ [ ]  │ [ ]  │ Jeton düşümü + SSE     │
│ PK request/accept/score  │ [ ]  │ [ ]  │ İki host veya host+view│
│ Music oda değişimi       │ [ ]  │ [ ]  │ Eski oda müzik durur   │
│ DM + bildirim unread     │ [ ]  │ [ ]  │ Gelen kutu             │
│ Logout A → login B       │ [ ]  │ [ ]  │ Cache izolasyonu       │
└─────────────────────────────────────────────────────────────────┘

Müzik detay (M5): docs/M5_DEVICE_TEST_CHECKLIST.md
  bash scripts/m5-device-prep.sh

Detay: docs/RELEASE_CHECKLIST.md § P1
Sonuç: P1 PASS veya FAIL (+ hangi satır)
EOF
