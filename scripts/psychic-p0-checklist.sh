#!/usr/bin/env bash
# Psychic TRTC P0 — iki cihaz kabul checklist (manuel test; agent çalıştırmaz).
set -euo pipefail

APK_URL="https://github.com/mesutbyrm/Cursor-Flutter-/releases/download/apk-latest/canlifal-mobile-release.apk"
VERSION="?"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
if [[ -f "${ROOT}/mobile/pubspec.yaml" ]]; then
  VERSION=$(grep -E '^version:' "${ROOT}/mobile/pubspec.yaml" | head -1 | sed 's/version:[[:space:]]*//')
fi

cat <<EOF
╔══════════════════════════════════════════════════════════════════╗
║  Psychic TRTC P0 — cihaz kabul (${VERSION})                    ║
╚══════════════════════════════════════════════════════════════════╝

APK: ${APK_URL}

Gereksinim: 2 fiziksel cihaz VEYA 2 hesap (danışan + falcı)

Her adımda kontrol: çift yönlü A/V · senkron · rejoin yok · duplicate stream yok

┌─────────────────────────────────────────────────────────────────┐
│ Zaman / senaryo          │ PASS │ FAIL │ Not                      │
├─────────────────────────────────────────────────────────────────┤
│ T0 join                  │ [ ]  │ [ ]  │ A/V anında her iki taraf │
│ T+1s                     │ [ ]  │ [ ]  │                          │
│ T+3s                     │ [ ]  │ [ ]  │                          │
│ T+5s (KRİTİK)            │ [ ]  │ [ ]  │ Eski bug ~5 sn donma     │
│ T+10s                    │ [ ]  │ [ ]  │                          │
│ T+30s                    │ [ ]  │ [ ]  │                          │
│ T+60s                    │ [ ]  │ [ ]  │                          │
│ WiFi ↔ mobil data        │ [ ]  │ [ ]  │ Kontrollü reconnect      │
│ Oturum A → B → A         │ [ ]  │ [ ]  │ Eski stream kapanır      │
│ Arka plan → ön plan      │ [ ]  │ [ ]  │ Gereksiz rejoin yok      │
└─────────────────────────────────────────────────────────────────┘

Genel akış (opsiyonel — LIVE_PSYCHICS_REMAINING.md):
  [ ] Danışan happy path (liste → görüşme → bitir → yorum)
  [ ] Falcı happy path (kabul → timer → bitir)
  [ ] Push kabul (arka planda bildirim)

Sonuç (birini işaretle):
  [ ] Psychic P0 PASS — RELEASE adayı
  [ ] Psychic P0 FAIL — logcat / ekran kaydı + adım notu

Detay: docs/LIVE_PSYCHICS_REMAINING.md
EOF
